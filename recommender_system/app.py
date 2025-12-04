from typing import List, Optional, Any, Dict, Tuple

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

# DÙNG IMPORT THẬT TỪ POCKETBASE CLIENT/SERVICE CỦA BẠN
from pocketbase_service import (
    get_user_details_by_user_id,
    get_all_other_user_details,
    create_recommendation_log,
    create_match_feedback,
)


# ---------- DOMAIN MODELS ----------


class UserDetails(BaseModel):
    id: str
    user_id: str

    # Basic profile
    fullname: Optional[str] = None
    avatar: Optional[str] = None
    gender: Optional[str] = None  # "male", "female"
    birthday: Optional[str] = None

    # Skill / play information
    # Ví dụ: "beginner", "lower intermediate", "intermediate", "upper intermediate", "advanced"
    level: Optional[str] = None
    # Dùng để tính toán: 1..5 theo schema của bạn
    level_numeric: int

    # Theo schema thật:
    # match_types: ['singles', 'doubles', 'mixed']
    match_types: List[str] = []

    # play_style_tags: ['attack', 'defense', 'net', 'baseline', 'all_round', 'fun', 'competitive']
    play_style_tags: List[str] = []

    preferred_role_doubles: Optional[str] = None  # "front", "back", "flexible"
    intensity: Optional[str] = None              # "casual", "semi_competitive", "competitive"

    # Experience & habit
    experience_years: Optional[float] = None
    plays_per_week: Optional[float] = None
    # Trong DB là relation tới courts -> lưu id sân (vd: "bv5emarj3ji1m32")
    home_court: Optional[str] = None

    @classmethod
    def from_pb_record(cls, record: Dict[str, Any]) -> "UserDetails":
        raw_level_numeric = record.get("level_numeric")

        if raw_level_numeric is None:
            raise ValueError("Record user_details thiếu trường 'level_numeric'")

        return cls(
            id=record["id"],
            user_id=record["user_id"],
            fullname=record.get("fullname"),
            avatar=record.get("avatar"),
            gender=record.get("gender"),
            birthday=record.get("birthday"),
            level=record.get("level"),
            level_numeric=int(raw_level_numeric),
            match_types=list(record.get("match_types") or []),
            play_style_tags=list(record.get("play_style_tags") or []),
            preferred_role_doubles=record.get("preferred_role_doubles"),
            intensity=record.get("intensity"),
            experience_years=record.get("experience_years"),
            plays_per_week=record.get("plays_per_week"),
            home_court=record.get("home_court"),
        )


class MatchCandidate(BaseModel):
    user: UserDetails
    score: float
    # Để debug: lưu được cả số điểm từng tiêu chí hoặc reason bị loại
    debug_info: Optional[Dict[str, Any]] = None


class MatchFeedbackRequest(BaseModel):
    """
    Payload nhận feedback sau khi chơi.
    """
    from_user_id: str           # ai đang đánh giá
    to_user_id: str             # đang đánh giá ai
    booking_id: Optional[str] = None  # trận / booking cụ thể (có thể None)
    feedback: str               # "good" | "ok" | "bad"
    comment: Optional[str] = None


# ---------- SCORING CONFIG ----------


class ScoringWeights(BaseModel):
    """
    Cấu hình trọng số.
    Tổng điểm tối đa ~100.
    """

    level: float = 40.0         # Trình độ vẫn quan trọng nhất
    play_style: float = 20.0    # Giảm nhẹ để nhường chỗ cho Role
    doubles_role: float = 20.0  # Tăng lên: Hợp vị trí đánh rất sướng
    intensity: float = 15.0     # Tăng lên: Cùng độ máu lửa mới bền
    home_court: float = 5.0     # Tiện đường đi lại (cùng sân / cùng court_id)
    habit: float = 0.0          # Tạm thời bỏ qua (hoặc để thấp)

    # Ngưỡng chênh lệch trình độ tối đa (level_numeric).
    # Với phong trào: chỉ chênh 2 level (vd: 1 vs 3) đã rất khó đánh,
    # nên chỉ cho phép chênh tối đa 1 level (vd: 1 vs 2, 2 vs 3, ...).
    max_level_diff: int = 1   # <--- ĐÃ SIẾT LẠI 1 THAY VÌ 3


DEFAULT_WEIGHTS = ScoringWeights()


# ---------- SCORING HELPERS ----------


def _intensity_value(intensity: Optional[str]) -> int:
    if intensity == "casual":
        return 1
    if intensity == "semi_competitive":
        return 2
    if intensity == "competitive":
        return 3
    return 2  # default trung bình


def _jaccard(a: List[str], b: List[str]) -> float:
    set_a = set(a)
    set_b = set(b)
    if not set_a and not set_b:
        return 0.0
    intersection = len(set_a & set_b)
    union = len(set_a | set_b)
    if union == 0:
        return 0.0
    return intersection / union


# ---------- LOGIC BỘ LỌC (HARD FILTERS) ----------


def _check_gender_compatibility(me: UserDetails, other: UserDetails) -> bool:
    """
    Kiểm tra giới tính + loại hình thi đấu:
    - Nếu không set match_types -> chấp nhận tất cả.
    - Nếu không có match_type chung -> loại.
    - mixed: phải khác giới (hard filter).
    - singles, doubles: không ràng buộc giới tính ở layer hard filter,
      có thể ưu tiên bằng scoring nếu sau này bạn muốn.
    """

    if not me.match_types:
        return True

    common = set(me.match_types) & set(other.match_types)
    if not common:
        return False

    # Hard filter chỉ giữ lại:
    # - mixed: phải khác giới
    # - singles, doubles: không loại nếu khác giới, chỉ ưu tiên khi chấm điểm sau
    if "mixed" in common:
        if me.gender and other.gender and me.gender == other.gender:
            return False  # mixed mà cùng giới thì loại

    return True


# ---------- SCORING BY ASPECT ----------


def _score_level(me: UserDetails, other: UserDetails, w: ScoringWeights) -> float:
    diff = abs(me.level_numeric - other.level_numeric)

    if diff == 0:
        factor = 1.0
    elif diff == 1:
        factor = 0.75
    elif diff == 2:
        factor = 0.4
    else:
        factor = 0.0

    # Lưu ý: với max_level_diff = 1, diff >= 2 đã bị loại ở hard filter,
    # nên nhánh diff == 2 ở đây thực tế không chạy, nhưng giữ để linh hoạt nếu sau này thay đổi.
    return factor * w.level


def _score_play_style(me: UserDetails, other: UserDetails, w: ScoringWeights) -> float:
    jaccard = _jaccard(me.play_style_tags, other.play_style_tags)
    return jaccard * w.play_style


def _score_doubles_role(me: UserDetails, other: UserDetails, w: ScoringWeights) -> float:
    """
    Logic đánh đôi:
    - Flexible + Flexible = 1.0
    - Front + Back = 1.0
    - Flexible + (Front/Back) = 0.8
    - Same role (Front+Front / Back+Back) = 0.2
    """
    role_a = me.preferred_role_doubles
    role_b = other.preferred_role_doubles

    if not role_a or not role_b:
        return 0.0

    if role_a == "flexible" and role_b == "flexible":
        factor = 1.0
    elif (role_a == "front" and role_b == "back") or (role_a == "back" and role_b == "front"):
        factor = 1.0
    elif "flexible" in (role_a, role_b):
        factor = 0.8
    elif role_a == role_b:
        factor = 0.2
    else:
        factor = 0.0

    return factor * w.doubles_role


def _score_intensity(me: UserDetails, other: UserDetails, w: ScoringWeights) -> float:
    int_a = _intensity_value(me.intensity)
    int_b = _intensity_value(other.intensity)
    diff_int = abs(int_a - int_b)

    if diff_int == 0:
        factor = 1.0
    elif diff_int == 1:
        factor = 0.5
    else:
        factor = 0.0

    return factor * w.intensity


def _score_home_court(me: UserDetails, other: UserDetails, w: ScoringWeights) -> float:
    """
    home_court trong DB là relation -> id sân (court_id).
    So sánh nhau bằng id là hợp lý:
    - cùng court_id => cùng sân yêu thích.
    """
    court_a = (me.home_court or "").strip()
    court_b = (other.home_court or "").strip()

    if court_a and court_b and court_a == court_b:
        return w.home_court

    return 0.0


def _score_habit(me: UserDetails, other: UserDetails, w: ScoringWeights) -> float:
    """
    Thói quen chơi: plays_per_week.
    (Hiện tại weight đang = 0 nên hàm này chưa ảnh hưởng,
     nhưng giữ lại để sau này tăng weight là xài được luôn.)
    """
    plays_a = me.plays_per_week or 0
    plays_b = other.plays_per_week or 0

    if plays_a == 0 or plays_b == 0:
        return 0.0

    diff = abs(plays_a - plays_b)
    if diff <= 1:
        factor = 1.0
    elif diff <= 3:
        factor = 0.5
    else:
        factor = 0.0

    return factor * w.habit


# ---------- OVERALL SCORE ----------


def compute_match_score(
    me: UserDetails,
    other: UserDetails,
    weights: ScoringWeights = DEFAULT_WEIGHTS,
) -> Tuple[float, Dict[str, Any]]:
    """
    Tính điểm ghép cặp.
    Trả về (Tổng điểm, Chi tiết điểm).
    Nếu bị loại bởi Hard Filter -> trả về (0.0, {"reason": ...}).
    """

    # Không tự ghép với chính mình (phòng hờ)
    if me.user_id == other.user_id:
        return 0.0, {"reason": "same_user"}

    # 1. Hard filter: chênh level quá lớn
    # Với max_level_diff = 1:
    #   - 1 vs 2 -> OK
    #   - 1 vs 3 -> LOẠI (reason: level_diff_too_high)
    if abs(me.level_numeric - other.level_numeric) > weights.max_level_diff:
        return 0.0, {"reason": "level_diff_too_high"}

    # 2. Hard filter: giới tính + loại hình thi đấu
    if not _check_gender_compatibility(me, other):
        return 0.0, {"reason": "gender_mismatch"}

    # 3. Tính điểm từng tiêu chí
    scores: Dict[str, float] = {}
    scores["level"] = _score_level(me, other, weights)
    scores["style"] = _score_play_style(me, other, weights)
    scores["role"] = _score_doubles_role(me, other, weights)
    scores["intensity"] = _score_intensity(me, other, weights)
    scores["court"] = _score_home_court(me, other, weights)
    scores["habit"] = _score_habit(me, other, weights)

    total_score = sum(scores.values())

    return total_score, scores


def recommend_partners(
    me: UserDetails,
    others: List[UserDetails],
    limit: int = 10,
    weights: ScoringWeights = DEFAULT_WEIGHTS,
) -> List[MatchCandidate]:
    candidates: List[MatchCandidate] = []

    for other in others:
        total_score, debug_details = compute_match_score(me, other, weights=weights)
        if total_score <= 0:
            continue

        candidates.append(
            MatchCandidate(
                user=other,
                score=round(total_score, 2),
                debug_info=debug_details,
            )
        )

    candidates.sort(key=lambda c: c.score, reverse=True)
    return candidates[:limit]


# ---------- LOGGING HELPERS ----------


async def log_recommendations(
    *,
    from_user_id: str,
    candidates: List[MatchCandidate],
    mode: str,  # "partner" | "friend"
) -> None:
    """
    Ghi log cho mỗi candidate vào collection recommendation_logs.

    - from_user_id: user đang được gợi ý danh sách
    - candidates  : danh sách gợi ý (MatchCandidate)
    - mode        : "partner" hoặc "friend" (để sau này dễ phân tích)
    """
    for index, c in enumerate(candidates, start=1):
        try:
            # copy debug_info (có thể là None)
            features: Dict[str, Any] = dict(c.debug_info or {})
            features["mode"] = mode

            await create_recommendation_log(
                from_user_id=from_user_id,
                to_user_id=c.user.user_id,
                rule_score=c.score,
                rank_in_list=index,
                features=features,
                invited=False,
                accepted=False,
            )
        except Exception as e:
            # Không làm vỡ response chỉ vì log lỗi
            print(
                f"[RECO_LOG][ERROR] cannot log recommendation "
                f"{from_user_id} -> {c.user.user_id}: {e}"
            )


# ---------- FASTAPI APP ----------


app = FastAPI(title="Badminton Recommendation Service")


@app.get("/health")
async def health_check():
    return {"status": "ok"}


@app.post("/feedback/match")
async def submit_match_feedback(payload: MatchFeedbackRequest):
    """
    Nhận feedback sau khi chơi:
    - from_user_id: người cho feedback
    - to_user_id  : người được đánh giá
    - booking_id  : trận/booking liên quan (có thể None)
    - feedback    : "good" | "ok" | "bad"
    - comment     : ghi chú thêm
    """
    try:
        record = await create_match_feedback(
            from_user_id=payload.from_user_id,
            to_user_id=payload.to_user_id,
            booking_id=payload.booking_id,
            feedback=payload.feedback,
            comment=payload.comment,
        )
        return {"status": "ok", "id": record.get("id")}
    except Exception as e:
        print("[MATCH_FEEDBACK][ERROR] cannot create match_feedback record:", e)
        raise HTTPException(status_code=500, detail="Cannot save feedback")


@app.get("/recommend/players", response_model=List[MatchCandidate])
async def recommend_players_endpoint(user_id: str, limit: int = 10):
    """
    Gợi ý người chơi cho user_id (id của user trong collection users / _pb_users_auth_).
    """

    # 1. Lấy user_details của current user
    me_record = await get_user_details_by_user_id(user_id)
    if not me_record:
        raise HTTPException(status_code=404, detail="User details not found")

    me = UserDetails.from_pb_record(me_record)

    # 2. Lấy user_details của tất cả user khác
    others_records = await get_all_other_user_details(user_id)
    if not others_records:
        return []

    others = [UserDetails.from_pb_record(r) for r in others_records]

    # 3. Tính score & trả về top
    candidates = recommend_partners(me, others, limit=limit, weights=DEFAULT_WEIGHTS)

    # 4. Ghi log recommendation (mode = "partner")
    await log_recommendations(
        from_user_id=user_id,
        candidates=candidates,
        mode="partner",
    )

    return candidates


# ---------------- FRIEND MODE CONFIG ---------------- #


class FriendScoringWeights(BaseModel):
    """
    Cấu hình trọng số dành riêng cho gợi ý kết bạn.
    Mục tiêu: tìm người có "gu chơi" và "sân nhà" giống nhau.
    """

    # Gợi ý kết bạn không cần trình độ quá sát
    level: float = 20.0

    # Hợp lối chơi khiến dễ làm bạn khi đánh chung
    play_style: float = 25.0

    # Intensity quan trọng vì những người cùng độ máu dễ hợp nhau
    intensity: float = 30.0

    # Rất quan trọng cho chức năng kết bạn: cùng sân → khả năng gặp nhau cao
    home_court: float = 25.0

    # Cho phép chênh level lớn hơn partner-mode
    max_level_diff: int = 2   # vd: 1 vs 3 vẫn accept


FRIEND_WEIGHTS = FriendScoringWeights()


def compute_friend_score(
    me: UserDetails,
    other: UserDetails,
    weights: FriendScoringWeights = FRIEND_WEIGHTS,
) -> Tuple[float, Dict[str, Any]]:
    """
    Mode FRIEND:
    - Không áp dụng giới tính / match_types
    - Level chỉ loại nếu quá lệch (>2)
    - Tập trung vào intensity, style và sân nhà
    """

    if me.user_id == other.user_id:
        return 0.0, {"reason": "same_user"}

    # 1. Level filter rất mềm
    if abs(me.level_numeric - other.level_numeric) > weights.max_level_diff:
        return 0.0, {"reason": "level_diff_too_high_for_friend"}

    # 2. Scoring
    scores: Dict[str, float] = {}

    # level
    diff = abs(me.level_numeric - other.level_numeric)
    if diff == 0:
        scores["level"] = 1.0 * weights.level
    elif diff == 1:
        scores["level"] = 0.6 * weights.level
    elif diff == 2:
        scores["level"] = 0.2 * weights.level
    else:
        scores["level"] = 0.0

    # play style
    scores["style"] = _jaccard(me.play_style_tags, other.play_style_tags) * weights.play_style

    # intensity
    int_diff = abs(_intensity_value(me.intensity) - _intensity_value(other.intensity))
    if int_diff == 0:
        scores["intensity"] = 1.0 * weights.intensity
    elif int_diff == 1:
        scores["intensity"] = 0.5 * weights.intensity
    else:
        scores["intensity"] = 0.0

    # home court
    scores["home_court"] = (
        weights.home_court if me.home_court and me.home_court == other.home_court else 0.0
    )

    total = sum(scores.values())
    return total, scores


def recommend_friends(
    me: UserDetails,
    others: List[UserDetails],
    limit: int = 10,
    weights: FriendScoringWeights = FRIEND_WEIGHTS,
) -> List[MatchCandidate]:

    candidates: List[MatchCandidate] = []

    for other in others:
        score, details = compute_friend_score(me, other, weights=weights)
        if score <= 0:
            continue

        candidates.append(
            MatchCandidate(
                user=other,
                score=round(score, 2),
                debug_info=details,
            )
        )

    candidates.sort(key=lambda c: c.score, reverse=True)
    return candidates[:limit]


# ---------------- FASTAPI ENDPOINT: FRIENDS ---------------- #


@app.get("/recommend/friends", response_model=List[MatchCandidate])
async def recommend_friends_endpoint(user_id: str, limit: int = 10):
    """
    Gợi ý KẾT BẠN:
    - Không xét giới tính
    - Không xét match_types
    - Level filter mềm
    - Ưu tiên: intensity, playstyle, home_court
    """

    me_record = await get_user_details_by_user_id(user_id)
    if not me_record:
        raise HTTPException(status_code=404, detail="User details not found")

    me = UserDetails.from_pb_record(me_record)

    others_records = await get_all_other_user_details(user_id)
    if not others_records:
        return []

    others = [UserDetails.from_pb_record(r) for r in others_records]

    candidates = recommend_friends(me, others, limit=limit, weights=FRIEND_WEIGHTS)

    # Ghi log recommendation (mode = "friend")
    await log_recommendations(
        from_user_id=user_id,
        candidates=candidates,
        mode="friend",
    )

    return candidates
