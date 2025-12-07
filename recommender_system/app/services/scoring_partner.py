from typing import Any, Dict, Tuple

from app.models.user_details import UserDetails
from app.models.weights import ScoringWeights
from app.services.scoring_base import intensity_value, jaccard
from app.services.filters import check_gender_compatibility


def score_level(me: UserDetails, other: UserDetails, w: ScoringWeights) -> float:
    diff = abs(me.level_numeric - other.level_numeric)

    if diff == 0:
        factor = 1.0
    elif diff == 1:
        factor = 0.75
    elif diff == 2:
        factor = 0.4
    else:
        factor = 0.0

    return factor * w.level


def score_play_style(me: UserDetails, other: UserDetails, w: ScoringWeights) -> float:
    j = jaccard(me.play_style_tags, other.play_style_tags)
    return j * w.play_style


def score_doubles_role(me: UserDetails, other: UserDetails, w: ScoringWeights) -> float:
    role_a = me.preferred_role_doubles
    role_b = other.preferred_role_doubles

    if not role_a or not role_b:
        return 0.0

    if role_a == "flexible" and role_b == "flexible":
        factor = 1.0
    elif (role_a == "front" and role_b == "back") or (role_a == "back" and role_b == "front"):
        factor = 1.0
    elif "flexible" in (role_a, role_b):
        factor = 0.8
    elif role_a == role_b:
        factor = 0.2
    else:
        factor = 0.0

    return factor * w.doubles_role


def score_intensity(me: UserDetails, other: UserDetails, w: ScoringWeights) -> float:
    int_a = intensity_value(me.intensity)
    int_b = intensity_value(other.intensity)
    diff_int = abs(int_a - int_b)

    if diff_int == 0:
        factor = 1.0
    elif diff_int == 1:
        factor = 0.5
    else:
        factor = 0.0

    return factor * w.intensity


def score_home_court(me: UserDetails, other: UserDetails, w: ScoringWeights) -> float:
    court_a = (me.home_court or "").strip()
    court_b = (other.home_court or "").strip()

    if court_a and court_b and court_a == court_b:
        return w.home_court

    return 0.0


def score_habit(me: UserDetails, other: UserDetails, w: ScoringWeights) -> float:
    plays_a = me.plays_per_week or 0
    plays_b = other.plays_per_week or 0

    if plays_a == 0 or plays_b == 0:
        return 0.0

    diff = abs(plays_a - plays_b)
    if diff <= 1:
        factor = 1.0
    elif diff <= 3:
        factor = 0.5
    else:
        factor = 0.0

    return factor * w.habit


def compute_match_score(
    me: UserDetails,
    other: UserDetails,
    weights: ScoringWeights,
) -> Tuple[float, Dict[str, Any]]:
    """
    Tính điểm ghép cặp partner.
    """

    if me.user_id == other.user_id:
        return 0.0, {"reason": "same_user"}

    if abs(me.level_numeric - other.level_numeric) > weights.max_level_diff:
        return 0.0, {"reason": "level_diff_too_high"}

    if not check_gender_compatibility(me, other):
        return 0.0, {"reason": "gender_mismatch"}

    scores: Dict[str, float] = {}
    scores["level"] = score_level(me, other, weights)
    scores["style"] = score_play_style(me, other, weights)
    scores["role"] = score_doubles_role(me, other, weights)
    scores["intensity"] = score_intensity(me, other, weights)
    scores["court"] = score_home_court(me, other, weights)
    scores["habit"] = score_habit(me, other, weights)

    total_score = sum(scores.values())
    return total_score, scores
