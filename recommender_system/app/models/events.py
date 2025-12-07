from typing import Optional
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
