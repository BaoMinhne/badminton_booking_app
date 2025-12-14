from typing import Optional, Literal, List
from pydantic import BaseModel, Field


class RecommendationShownEvent(BaseModel):
    """
    Log khi UI đã render xong danh sách gợi ý.
    - session_id: 1 phiên mở trang gợi ý
    - items: danh sách các candidate được hiển thị kèm thứ hạng
    """
    from_user_id: str
    session_id: str
    mode: Literal["partner", "friend"] = "partner"
    items: List["ShownItem"]


class ShownItem(BaseModel):
    to_user_id: str
    rank_shown: int = Field(ge=1)
    log_id: Optional[str] = None  # nếu UI có log_id thì update theo id là chuẩn nhất


RecommendationShownEvent.model_rebuild()


class RecommendationClickEvent(BaseModel):
    """Log khi user click xem hồ sơ của 1 gợi ý."""
    from_user_id: str
    to_user_id: str
    session_id: Optional[str] = None
    mode: Optional[Literal["partner", "friend"]] = None
    log_id: Optional[str] = None


class RecommendationDismissEvent(BaseModel):
    """Log khi user dismiss / không quan tâm 1 gợi ý."""
    from_user_id: str
    to_user_id: str
    session_id: Optional[str] = None
    reason: Optional[str] = None
    mode: Optional[Literal["partner", "friend"]] = None
    log_id: Optional[str] = None


class RecommendationOutcomeEvent(BaseModel):
    """
    Log outcome nếu bạn muốn ghi reject/ignored (không bắt buộc).
    Ví dụ: người nhận từ chối lời mời kết bạn.
    """
    from_user_id: str
    to_user_id: str
    outcome: Literal["accepted", "rejected", "ignored"]
    session_id: Optional[str] = None
    mode: Optional[Literal["partner", "friend"]] = None
    log_id: Optional[str] = None
