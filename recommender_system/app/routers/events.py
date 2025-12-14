from fastapi import APIRouter, HTTPException

from pocketbase_service import (
    mark_recommendation_invited,
    mark_recommendation_accepted,
    mark_recommendation_shown,
    mark_recommendation_clicked_profile,
    mark_recommendation_dismissed,
    mark_recommendation_outcome,
)

from app.models.events import (
    InvitationEvent,
    RecommendationActionEvent,
    RecommendationClickedEvent,
    RecommendationDismissEvent,
    RecommendationOutcomeEvent,
    RecommendationShownEvent,
)

router = APIRouter(prefix="/events", tags=["events"])


@router.post("/invitations/sent")
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


@router.post("/invitations/accepted")
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


@router.post("/recommendations/shown")
async def recommendation_shown(event: RecommendationShownEvent):
    """
    UI gọi khi danh sách gợi ý đã được render.
    """

    try:
        for item in event.items:
            await mark_recommendation_shown(
                from_user_id=event.from_user_id,
                to_user_id=item.to_user_id,
                session_id=event.session_id,
                rank_shown=item.rank_shown,
            )

        return {"status": "ok"}
    except Exception as e:
        print("[RECO_SHOWN][ERROR]", e)
        raise HTTPException(status_code=500, detail="Cannot mark as shown")


@router.post("/recommendations/clicked_profile")
async def recommendation_clicked(event: RecommendationClickedEvent):
    """
    UI gọi khi user click xem hồ sơ một gợi ý.
    """

    try:
        await mark_recommendation_clicked_profile(
            from_user_id=event.from_user_id,
            to_user_id=event.to_user_id,
        )
        return {"status": "ok"}
    except Exception as e:
        print("[RECO_CLICK_PROFILE][ERROR]", e)
        raise HTTPException(status_code=500, detail="Cannot mark as clicked")


@router.post("/recommendations/action")
async def recommendation_action(event: RecommendationActionEvent):
    """
    Log hành động khi user tương tác với gợi ý (gửi lời mời, accept,...).
    """

    try:
        if event.action == "invited":
            await mark_recommendation_invited(
                from_user_id=event.from_user_id,
                to_user_id=event.to_user_id,
            )
        elif event.action == "accepted":
            await mark_recommendation_accepted(
                from_user_id=event.from_user_id,
                to_user_id=event.to_user_id,
            )
        else:
            raise HTTPException(status_code=400, detail="Unknown action")

        return {"status": "ok"}
    except HTTPException:
        raise
    except Exception as e:
        print("[RECO_ACTION][ERROR]", e)
        raise HTTPException(status_code=500, detail="Cannot log action")


@router.post("/recommendations/outcome")
async def recommendation_outcome(event: RecommendationOutcomeEvent):
    """
    Log kết quả cuối cùng của gợi ý.
    """

    try:
        await mark_recommendation_outcome(
            from_user_id=event.from_user_id,
            to_user_id=event.to_user_id,
            outcome=event.outcome,
        )
        return {"status": "ok"}
    except Exception as e:
        print("[RECO_OUTCOME][ERROR]", e)
        raise HTTPException(status_code=500, detail="Cannot log outcome")


@router.post("/recommendations/dismiss")
async def recommendation_dismiss(event: RecommendationDismissEvent):
    """
    Log khi user ẩn/không quan tâm gợi ý.
    """

    try:
        await mark_recommendation_dismissed(
            from_user_id=event.from_user_id,
            to_user_id=event.to_user_id,
            reason=event.reason,
        )
        return {"status": "ok"}
    except Exception as e:
        print("[RECO_DISMISS][ERROR]", e)
        raise HTTPException(status_code=500, detail="Cannot dismiss recommendation")
