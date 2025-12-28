from fastapi import APIRouter, HTTPException

from pocketbase_service import create_match_feedback
from app.models.feedback import MatchFeedbackRequest

router = APIRouter(prefix="/feedback", tags=["feedback"])


@router.post("/match")
async def submit_match_feedback(payload: MatchFeedbackRequest):
    """
    Nhận feedback sau khi chơi.
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
