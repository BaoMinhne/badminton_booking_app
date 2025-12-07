from typing import List, Optional, Any, Dict
from pydantic import BaseModel


class UserDetails(BaseModel):
    id: str
    user_id: str

    # Basic profile
    fullname: Optional[str] = None
    avatar: Optional[str] = None
    gender: Optional[str] = None  # "male", "female"
    birthday: Optional[str] = None

    # Skill / play information
    level: Optional[str] = None
    level_numeric: int

    # match_types: ['singles', 'doubles', 'mixed']
    match_types: List[str] = []

    # play_style_tags: ['attack', 'defense', 'net', 'baseline', 'all_round', 'fun', 'competitive']
    play_style_tags: List[str] = []

    preferred_role_doubles: Optional[str] = None  # "front", "back", "flexible"
    intensity: Optional[str] = None              # "casual", "semi_competitive", "competitive"

    # Experience & habit
    experience_years: Optional[float] = None
    plays_per_week: Optional[float] = None

    # home_court: id sân (relation tới courts)
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
