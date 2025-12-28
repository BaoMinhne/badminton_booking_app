from pydantic import BaseModel


class ScoringWeights(BaseModel):
    """
    Cấu hình trọng số cho gợi ý partner.
    Tổng điểm tối đa ~100.
    """
    level: float = 40.0
    play_style: float = 20.0
    doubles_role: float = 20.0
    intensity: float = 15.0
    home_court: float = 5.0
    habit: float = 0.0

    # Ngưỡng chênh lệch trình độ tối đa (level_numeric)
    max_level_diff: int = 1


DEFAULT_WEIGHTS = ScoringWeights()


class FriendScoringWeights(BaseModel):
    """
    Cấu hình trọng số dành riêng cho gợi ý kết bạn.
    Mục tiêu: tìm người có "gu chơi" và "sân nhà" giống nhau.
    """

    # Gợi ý kết bạn không cần trình độ quá sát
    level: float = 20.0

    # Hợp lối chơi khiến dễ làm bạn khi đánh chung
    play_style: float = 25.0

    # Intensity quan trọng vì những người cùng độ máu dễ hợp nhau
    intensity: float = 30.0

    # Rất quan trọng cho chức năng kết bạn: cùng sân → khả năng gặp nhau cao
    home_court: float = 25.0

    # Cho phép chênh level lớn hơn partner-mode
    max_level_diff: int = 2   # vd: 1 vs 3 vẫn accept


FRIEND_WEIGHTS = FriendScoringWeights()
