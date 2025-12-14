from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from typing import List, Optional, Literal

from pocketbase_service import (
    mark_recommendation_shown,
    mark_recommendation_clicked_profile,
    mark_recommendation_dismissed,
    mark_recommendation_outcome,
    mark_recommendation_invited,
    mark_recommendation_accepted,
)

router = APIRouter(prefix="/events/recommendations", tags=["recommendation-events"])


class ShownItem(BaseModel):
    to_user_id: str
    rank_shown: int = Field(ge=1)


class ShownEvent(BaseModel):
    from_user_id: str
    session_id: str
    items: List[ShownItem]


@router.post("/shown")
async def log_shown(event: ShownEvent):
    try:
        for it in event.items:
            await mark_recommendation_shown(
                from_user_id=event.from_user_id,
                to_user_id=it.to_user_id,
                session_id=event.session_id,
                rank_shown=it.rank_shown,
            )
        return {"status": "ok", "count": len(event.items)}
    except Exception as e:
        print("[RECO_SHOWN][ERROR]", e)
        raise HTTPException(status_code=500, detail="failed to log shown")


class ClickEvent(BaseModel):
    from_user_id: str
    to_user_id: str


@router.post("/clicked_profile")
async def log_clicked_profile(event: ClickEvent):
    try:
        await mark_recommendation_clicked_profile(
            from_user_id=event.from_user_id,
            to_user_id=event.to_user_id,
        )
        return {"status": "ok"}
    except Exception as e:
        print("[RECO_CLICK][ERROR]", e)
        raise HTTPException(status_code=500, detail="failed to log click")


class DismissEvent(BaseModel):
    from_user_id: str
    to_user_id: str
    reason: Optional[str] = None


@router.post("/dismiss")
async def log_dismiss(event: DismissEvent):
    try:
        await mark_recommendation_dismissed(
            from_user_id=event.from_user_id,
            to_user_id=event.to_user_id,
            reason=event.reason,
        )
        return {"status": "ok"}
    except Exception as e:
        print("[RECO_DISMISS][ERROR]", e)
        raise HTTPException(status_code=500, detail="failed to log dismiss")


class ActionEvent(BaseModel):
    from_user_id: str
    to_user_id: str
    action: Literal["invited", "accepted"]


@router.post("/action")
async def log_action(event: ActionEvent):
    """
    Dùng chung cho 2 hành động mạnh: invited / accepted.
    (Bạn đang có hàm mark_recommendation_invited/accepted sẵn)
    """
    try:
        if event.action == "invited":
            await mark_recommendation_invited(event.from_user_id, event.to_user_id)
        else:
            await mark_recommendation_accepted(event.from_user_id, event.to_user_id)
        return {"status": "ok"}
    except Exception as e:
        print("[RECO_ACTION][ERROR]", e)
        raise HTTPException(status_code=500, detail="failed to log action")


class OutcomeEvent(BaseModel):
    from_user_id: str
    to_user_id: str
    outcome: Literal["accepted", "rejected", "ignored"]


@router.post("/outcome")
async def log_outcome(event: OutcomeEvent):
    try:
        await mark_recommendation_outcome(
            from_user_id=event.from_user_id,
            to_user_id=event.to_user_id,
            outcome=event.outcome,
        )
        return {"status": "ok"}
    except Exception as e:
        print("[RECO_OUTCOME][ERROR]", e)
        raise HTTPException(status_code=500, detail="failed to log outcome")
