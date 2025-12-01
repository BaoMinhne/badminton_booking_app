from typing import List, Optional, Any, Dict

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

from pocketbase_client import (
    get_user_details_by_user_id,
    get_all_other_user_details,
)


# ---------- DOMAIN MODELS ----------


class UserDetails(BaseModel):
    id: str
    user_id: str

    # Basic profile
    fullname: Optional[str] = None
    avatar: Optional[str] = None
    gender: Optional[str] = None
    birthday: Optional[str] = None  # keep string for now

    # Skill / play information
    level: Optional[str] = None
    level_numeric: int

    match_types: List[str] = []  # ["singles", "doubles", "mixed"]
    play_style_tags: List[str] = []  # ["attacking", "defensive", ...]
    preferred_role_doubles: Optional[str] = None  # "front", "back", "flexible"
    intensity: Optional[str] = None  # "casual", "semi_competitive", "competitive"

    # Experience & habit
    experience_years: Optional[float] = None
    plays_per_week: Optional[float] = None
    home_court: Optional[str] = None

    @classmethod
    def from_pb_record(cls, record: Dict[str, Any]) -> "UserDetails":
        """
        Chuẩn hoá mapping từ PocketBase record sang UserDetails.

        - Bắt buộc có level_numeric (để đảm bảo model có thể ghép).
        - Các field còn lại để optional, không có thì gán None / [].
        """
        raw_level_numeric = record.get("level_numeric")

        if raw_level_numeric is None:
            # Bắt buộc phải có level_numeric để ghép trình độ
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


# ---------- SCORING CONFIG ----------


class ScoringWeights(BaseModel):
    """
    Cho phép cấu hình trọng số cho từng nhóm tiêu chí.

    Mặc định tổng điểm tối đa ~100, để sau này dễ scale / hiển thị %.
    """

    # Max weights cho từng nhóm
    level: float = 40.0
    play_style: float = 25.0
    doubles_role: float = 15.0
    intensity: float = 10.0
    home_court: float = 5.0
    habit: float = 5.0  # plays_per_week / experience_years

    # Ngưỡng chênh lệch trình độ cho phép (quá lớn thì loại luôn)
    max_level_diff: int = 3  # nếu chênh > 3 level thì coi như rất khó hợp


DEFAULT_WEIGHTS = ScoringWeights()


# ---------- SCORING HELPERS ----------


def _intensity_value(intensity: str | None) -> int:
    if intensity == "casual":
        return 1
    if intensity == "semi_competitive":
        return 2
    if intensity == "competitive":
        return 3
    return 2  # default trung bình nếu thiếu dữ liệu


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


# ---------- SCORING BY ASPECT ----------


def _score_level(me: UserDetails, other: UserDetails, w: ScoringWeights) -> float:
    """
    Chênh lệch trình độ càng ít càng tốt.
    diff = 0  -> 100% điểm level
    diff = 1  -> 0.75
    diff = 2  -> 0.4
    diff >= 3 -> 0.0
    """
    diff = abs(me.level_numeric - other.level_numeric)

    if diff == 0:
        factor = 1.0
    elif diff == 1:
        factor = 0.75
    elif diff == 2:
        factor = 0.4
    else:
        factor = 0.0

    return factor * w.level


def _score_play_style(me: UserDetails, other: UserDetails, w: ScoringWeights) -> float:
    """
    Dùng Jaccard similarity trên play_style_tags, nhân với trọng số.
    """
    jaccard = _jaccard(me.play_style_tags, other.play_style_tags)
    return jaccard * w.play_style


def _score_doubles_role(me: UserDetails, other: UserDetails, w: ScoringWeights) -> float:
    """
    Ghép đôi: front/back là combo tốt nhất.
    Cả hai flexible thì cũng khá ổn.
    Cùng role (front-front/back-back) thì vẫn có điểm nhưng thấp.
    """
    role_a = me.preferred_role_doubles
    role_b = other.preferred_role_doubles

    if not role_a or not role_b:
        return 0.0

    # perfect complement
    if (role_a == "front" and role_b == "back") or (
        role_a == "back" and role_b == "front"
    ):
        factor = 1.0
    # cả hai đều flexible
    elif role_a == "flexible" and role_b == "flexible":
        factor = 0.8
    # một flexible, một front/back
    elif role_a == "flexible" or role_b == "flexible":
        factor = 0.7
    # cùng role (front-front / back-back)
    elif role_a == role_b:
        factor = 0.4
    else:
        factor = 0.0

    return factor * w.doubles_role


def _score_intensity(me: UserDetails, other: UserDetails, w: ScoringWeights) -> float:
    """
    Mức độ try-hard tương đồng thì tốt.
    diff = 0 -> full
    diff = 1 -> 0.5
    diff >=2 -> 0
    """
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
    if me.home_court and other.home_court and me.home_court == other.home_court:
        return w.home_court
    return 0.0


def _score_habit(me: UserDetails, other: UserDetails, w: ScoringWeights) -> float:
    """
    Thói quen chơi: dựa trên plays_per_week & experience_years.
    Ở mức demo: chỉ kiểm tra plays_per_week, chênh lệch ít thì cộng điểm.
    """
    plays_a = me.plays_per_week or 0
    plays_b = other.plays_per_week or 0

    if plays_a == 0 or plays_b == 0:
        # không có dữ liệu thì không cộng điểm
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
) -> float:
    """
    Tính tổng điểm ghép cặp giữa 2 người chơi.
    Trả về số thực, càng cao càng hợp.
    """

    # Nếu chênh trình độ quá lớn thì cho score = 0 luôn để loại sớm.
    if abs(me.level_numeric - other.level_numeric) > weights.max_level_diff:
        return 0.0

    score = 0.0

    score += _score_level(me, other, weights)
    score += _score_play_style(me, other, weights)
    score += _score_doubles_role(me, other, weights)
    score += _score_intensity(me, other, weights)
    score += _score_home_court(me, other, weights)
    score += _score_habit(me, other, weights)

    return score


def recommend_partners(
    me: UserDetails,
    others: List[UserDetails],
    limit: int = 10,
    weights: ScoringWeights = DEFAULT_WEIGHTS,
) -> List[MatchCandidate]:
    """
    Tính score cho toàn bộ 'others' và trả về top N ứng viên.
    """
    candidates: List[MatchCandidate] = []

    for other in others:
        s = compute_match_score(me, other, weights=weights)
        if s <= 0:
            continue
        candidates.append(MatchCandidate(user=other, score=s))

    candidates.sort(key=lambda c: c.score, reverse=True)
    return candidates[:limit]


# ---------- FASTAPI APP ----------


app = FastAPI(title="Badminton Recommendation Service")


@app.get("/health")
async def health_check():
    return {"status": "ok"}


@app.get("/recommend/players", response_model=List[MatchCandidate])
async def recommend_players_endpoint(user_id: str, limit: int = 10):
    """
    Gợi ý người chơi dựa trên dữ liệu thật từ PocketBase (collection user_details).

    - user_id: id của user trong collection _pb_users_auth_ (id đang login trong app).
    """

    # 1. Lấy user_details của current user
    me_record = await get_user_details_by_user_id(user_id)
    if not me_record:
        raise HTTPException(
            status_code=404,
            detail="User details not found for this user_id",
        )

    me = UserDetails.from_pb_record(me_record)

    # 2. Lấy user_details của tất cả user khác
    others_records = await get_all_other_user_details(user_id)
    others = [UserDetails.from_pb_record(r) for r in others_records]

    if not others:
        return []

    # 3. Tính score & lấy top
    candidates = recommend_partners(me, others, limit=limit)
    return candidates
