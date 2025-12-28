from typing import List

from fastapi import APIRouter, HTTPException

from pocketbase_service import (
    get_user_details_by_user_id,
    get_all_other_user_details,
)

from app.models.user_details import UserDetails
from app.models.match_candidate import MatchCandidate
from app.services.recommender import recommend_partners, recommend_friends
from app.services.logging_service import log_recommendations

router = APIRouter(prefix="/recommend", tags=["recommend"])


@router.get("/players", response_model=List[MatchCandidate])
async def recommend_players_endpoint(user_id: str, limit: int = 10, offset: int = 0):
    """
    Gợi ý người chơi (partner) cho user_id.
    """

    if limit <= 0:
        raise HTTPException(status_code=400, detail="limit must be positive")

    offset = max(offset, 0)

    me_record = await get_user_details_by_user_id(user_id)
    if not me_record:
        raise HTTPException(status_code=404, detail="User details not found")

    me = UserDetails.from_pb_record(me_record)

    others_records = await get_all_other_user_details(user_id)
    if not others_records:
        return []

    others = [UserDetails.from_pb_record(r) for r in others_records]

    candidates = recommend_partners(me, others, limit=limit, offset=offset)

    await log_recommendations(
        from_user_id=user_id,
        candidates=candidates,
        mode="partner",
        start_rank=offset + 1,
    )

    return candidates


@router.get("/friends", response_model=List[MatchCandidate])
async def recommend_friends_endpoint(user_id: str, limit: int = 10, offset: int = 0):
    """
    Gợi ý KẾT BẠN.
    """

    if limit <= 0:
        raise HTTPException(status_code=400, detail="limit must be positive")

    offset = max(offset, 0)

    me_record = await get_user_details_by_user_id(user_id)
    if not me_record:
        raise HTTPException(status_code=404, detail="User details not found")

    me = UserDetails.from_pb_record(me_record)

    others_records = await get_all_other_user_details(user_id)
    if not others_records:
        return []

    others = [UserDetails.from_pb_record(r) for r in others_records]

    candidates = recommend_friends(me, others, limit=limit, offset=offset)

    await log_recommendations(
        from_user_id=user_id,
        candidates=candidates,
        mode="friend",
        start_rank=offset + 1,
    )

    return candidates
