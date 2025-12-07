from fastapi import APIRouter, HTTPException

from pocketbase_service import (
    mark_recommendation_invited,
    mark_recommendation_accepted,
)

from app.models.events import InvitationEvent

router = APIRouter(prefix="/events/invitations", tags=["events"])


@router.post("/sent")
async def invitation_sent(event: InvitationEvent):
    """
    Gọi khi user A gửi lời mời cho user B.
    """
    try:
        await mark_recommendation_invited(
            from_user_id=event.from_user_id,
            to_user_id=event.to_user_id,
        )
        return {"status": "ok"}
    except Exception as e:
        print("[INVITATION_SENT][ERROR]", e)
        raise HTTPException(status_code=500, detail="Cannot mark as invited")


@router.post("/accepted")
async def invitation_accepted(event: InvitationEvent):
    """
    Gọi khi user B chấp nhận lời mời của A.
    """
    try:
        await mark_recommendation_accepted(
            from_user_id=event.from_user_id,
            to_user_id=event.to_user_id,
        )
        return {"status": "ok"}
    except Exception as e:
        print("[INVITATION_ACCEPTED][ERROR]", e)
        raise HTTPException(status_code=500, detail="Cannot mark as accepted")
