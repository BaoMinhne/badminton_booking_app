from typing import List, Optional
from pydantic import BaseModel


class InvitationEvent(BaseModel):
    """
    Event lời mời sân:
    - from_user_id: người gửi lời mời
    - to_user_id  : người nhận lời mời
    - invitation_id: id record trong collection invitations (nếu muốn lưu lại, có thể None)
    - mode        : 'partner' / 'friend' / 'manual'... (tùy app bạn dùng)
    """
    from_user_id: str
    to_user_id: str
    invitation_id: Optional[str] = None
    mode: Optional[str] = None


class RecommendationShownItem(BaseModel):
    to_user_id: str
    rank_shown: int


class RecommendationShownEvent(BaseModel):
    from_user_id: str
    session_id: str
    items: List[RecommendationShownItem]


class RecommendationClickedEvent(BaseModel):
    from_user_id: str
    to_user_id: str


class RecommendationActionEvent(BaseModel):
    from_user_id: str
    to_user_id: str
    action: str  # invited | accepted


class RecommendationOutcomeEvent(BaseModel):
    from_user_id: str
    to_user_id: str
    outcome: str  # accepted | rejected | ignored


class RecommendationDismissEvent(BaseModel):
    from_user_id: str
    to_user_id: str
    reason: Optional[str] = None
