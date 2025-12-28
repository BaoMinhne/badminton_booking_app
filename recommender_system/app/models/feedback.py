from typing import Optional
from pydantic import BaseModel


class MatchFeedbackRequest(BaseModel):
    """
    Payload nhận feedback sau khi chơi.
    """
    from_user_id: str           # ai đang đánh giá
    to_user_id: str             # đang đánh giá ai
    booking_id: Optional[str] = None  # trận / booking cụ thể (có thể None)
    feedback: str               # "good" | "ok" | "bad"
    comment: Optional[str] = None
