from typing import Any, Dict, Tuple

from app.models.user_details import UserDetails
from app.models.weights import FriendScoringWeights
from app.services.scoring_base import intensity_value, jaccard


def compute_friend_score(
    me: UserDetails,
    other: UserDetails,
    weights: FriendScoringWeights,
) -> Tuple[float, Dict[str, Any]]:
    """
    Mode FRIEND:
    - Không áp dụng giới tính / match_types
    - Level chỉ loại nếu quá lệch (>2)
    - Tập trung vào intensity, style và sân nhà
    """

    if me.user_id == other.user_id:
        return 0.0, {"reason": "same_user"}

    if abs(me.level_numeric - other.level_numeric) > weights.max_level_diff:
        return 0.0, {"reason": "level_diff_too_high_for_friend"}

    scores: Dict[str, float] = {}

    diff = abs(me.level_numeric - other.level_numeric)
    if diff == 0:
        scores["level"] = 1.0 * weights.level
    elif diff == 1:
        scores["level"] = 0.6 * weights.level
    elif diff == 2:
        scores["level"] = 0.2 * weights.level
    else:
        scores["level"] = 0.0

    scores["style"] = jaccard(me.play_style_tags, other.play_style_tags) * weights.play_style

    int_diff = abs(intensity_value(me.intensity) - intensity_value(other.intensity))
    if int_diff == 0:
        scores["intensity"] = 1.0 * weights.intensity
    elif int_diff == 1:
        scores["intensity"] = 0.5 * weights.intensity
    else:
        scores["intensity"] = 0.0

    scores["home_court"] = (
        weights.home_court if me.home_court and me.home_court == other.home_court else 0.0
    )

    total = sum(scores.values())
    return total, scores
