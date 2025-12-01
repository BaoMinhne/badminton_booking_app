from typing import List, Optional
from typing import Any, Dict

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

from pocketbase_client import (
    get_user_details_by_user_id,
    get_all_other_user_details,
)

# ---------- MODELS ----------

class UserDetails(BaseModel):
    id: str
    user_id: str
    fullname: Optional[str] = None
    avatar: Optional[str] = None
    gender: Optional[str] = None
    birthday: Optional[str] = None  # tạm để string

    level: Optional[str] = None
    level_numeric: int

    match_types: List[str] = []
    play_style_tags: List[str] = []
    preferred_role_doubles: Optional[str] = None
    intensity: Optional[str] = None

    experience_years: Optional[float] = None
    plays_per_week: Optional[float] = None
    home_court: Optional[str] = None

    @classmethod
    def from_pb_record(cls, record: Dict[str, Any]) -> "UserDetails":
        raw_level_numeric = record.get("level_numeric")

        if raw_level_numeric is None:
            # Có thể chọn raise error hoặc gán default
            # Ở đây mình raise luôn cho dễ debug
            raise ValueError("Record user_details thiếu trường 'level_numeric'")

        return cls(
            id=record["id"],
            user_id=record["user_id"],
            fullname=record.get("fullname"),
            avatar=record.get("avatar"),
            gender=record.get("gender"),
            birthday=record.get("birthday"),
            level=record.get("level"),
            level_numeric=int(raw_level_numeric),  # ép kiểu int rõ ràng
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


# ---------- RECOMMENDER LOGIC ----------

def intensity_value(intensity: str | None) -> int:
    if intensity == "casual":
        return 1
    if intensity == "semi_competitive":
        return 2
    if intensity == "competitive":
        return 3
    return 2  # default trung bình


def compute_match_score(me: UserDetails, other: UserDetails) -> float:
    score = 0.0

    # 1. Trình độ (40 điểm)
    diff_level = abs(me.level_numeric - other.level_numeric)
    if diff_level == 0:
        score += 40
    elif diff_level == 1:
        score += 30
    elif diff_level == 2:
        score += 10
    else:
        score -= 100

    # 2. Lối đánh (30 điểm)
    set_a = set(me.play_style_tags)
    set_b = set(other.play_style_tags)
    if set_a or set_b:
        intersection = len(set_a & set_b)
        union = len(set_a | set_b)
        jaccard = 0.0 if union == 0 else intersection / union
        score += jaccard * 30.0

    # 3. Vai trò trong đôi (15 điểm)
    role_a = me.preferred_role_doubles
    role_b = other.preferred_role_doubles
    if role_a and role_b:
        if (role_a == "front" and role_b == "back") or (
            role_a == "back" and role_b == "front"
        ):
            score += 15
        elif role_a == role_b:
            score += 5
        elif role_a == "flexible" or role_b == "flexible":
            score += 10

    # 4. Mức độ try-hard (10 điểm)
    int_a = intensity_value(me.intensity)
    int_b = intensity_value(other.intensity)
    diff_int = abs(int_a - int_b)
    if diff_int == 0:
        score += 10
    elif diff_int == 1:
        score += 5
    else:
        score -= 5

    # 5. Cùng sân (5 điểm)
    if me.home_court and other.home_court and me.home_court == other.home_court:
        score += 5

    return score


def recommend_partners(me: UserDetails, others: List[UserDetails], limit: int = 10) -> List[MatchCandidate]:
    candidates: List[MatchCandidate] = []
    for other in others:
        s = compute_match_score(me, other)
        if s > 0:
            candidates.append(MatchCandidate(user=other, score=s))

    candidates.sort(key=lambda c: c.score, reverse=True)
    return candidates[:limit]


# ---------- FASTAPI APP ----------

app = FastAPI(title="Badminton Recommendation Service")


@app.get("/health")
async def health_check():
    return {"status": "ok"}


@app.get("/recommend/players", response_model=List[MatchCandidate])
async def recommend_players(user_id: str, limit: int = 10):
    """
    Gợi ý người chơi dựa trên dữ liệu thật từ PocketBase (collection user_details).

    - user_id: id của user trong collection _pb_users_auth_ (id đang login trong app).
    """

    # 1. Lấy user_details của current user
    me_record = await get_user_details_by_user_id(user_id)
    if not me_record:
        raise HTTPException(status_code=404, detail="User details not found for this user_id")

    me = UserDetails.from_pb_record(me_record)

    # 2. Lấy user_details của tất cả user khác
    others_records = await get_all_other_user_details(user_id)
    others = [UserDetails.from_pb_record(r) for r in others_records]

    if not others:
        return []

    # 3. Tính score & lấy top
    candidates = recommend_partners(me, others, limit=limit)
    return candidates
