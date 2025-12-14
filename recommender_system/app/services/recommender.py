# app/services/recommender.py
from typing import List, Dict, Any

from app.models.user_details import UserDetails
from app.models.match_candidate import MatchCandidate
from app.models.weights import DEFAULT_WEIGHTS, FRIEND_WEIGHTS
from app.services.scoring_partner import compute_match_score
from app.services.scoring_friend import compute_friend_score
from app.services.scoring_base import jaccard, intensity_value
from app.services.logistic_regression import predict_accept_probability


# --------- BUILD FEATURES FEED VÀO ML (MODE PARTNER) --------- #


def _build_logistic_regression_features_for_partner(
    me: UserDetails,
    other: UserDetails,
    rule_score: float,
    rank_in_list: int,
    debug_details: Dict[str, Any],
) -> Dict[str, float]:
    """Build feature cho ML.

    Hiện tại bạn train với CLEAN_MODE=True và schema mới (prefix f_*), vì vậy
    hàm này sẽ xuất ra *đồng thời* 2 bộ key:

    - Schema mới (khuyến nghị):
      ['rule_score','rank_in_list','f_level','f_style','f_role','f_intensity',
       'f_home_court','f_habit','f_court','is_top3']

    - Schema cũ (để tương thích nếu bạn retrain/rollback):
      ['rule_score','rank_in_list','level','style','role','intensity',
       'home_court','habit','court','is_top3']

    Các biến sim_p_* chỉ tồn tại trong dữ liệu giả → runtime luôn set = 0.
    """

    # level: lấy level_numeric của đối thủ (other)
    level_val = float(other.level_numeric)

    # style: dùng lại jaccard playstyle (0..1)
    style_val = float(jaccard(me.play_style_tags, other.play_style_tags))

    # role, intensity, court, habit: nếu đã có trong debug_details thì tận dụng luôn
    role_val = float(debug_details.get("role", 0.0))
    intensity_val = float(debug_details.get("intensity", 0.0))
    court_val = float(debug_details.get("court", 0.0))
    habit_val = float(debug_details.get("habit", 0.0))

    # home_court: flag 0/1 xem có cùng sân nhà không
    home_court_same = 1.0 if (me.home_court and me.home_court == other.home_court) else 0.0

    # sim_p_*: chỉ tồn tại trong dataset training synthetic -> runtime set 0
    sim_p_accepted = 0.0
    sim_p_invited = 0.0

    # is_top3: 1 nếu rule-based rank nằm trong top 3, ngược lại 0
    is_top3 = 1.0 if rank_in_list <= 3 else 0.0

    # Xuất ra cả 2 schema để service ML tự chọn schema phù hợp với artifact.
    return {
        "rule_score": float(rule_score),
        "rank_in_list": float(rank_in_list),

        # schema mới (f_*)
        "f_level": level_val,
        "f_style": style_val,
        "f_role": role_val,
        "f_intensity": intensity_val,
        "f_home_court": home_court_same,
        "f_habit": habit_val,
        "f_court": court_val,

        # schema cũ (không prefix)
        "level": level_val,
        "style": style_val,
        "role": role_val,
        "intensity": intensity_val,
        "home_court": home_court_same,
        "habit": habit_val,
        "court": court_val,

        # synthetic placeholders
        "sim_p_accepted": sim_p_accepted,
        "sim_p_invited": sim_p_invited,
        "f_sim_p_accepted": sim_p_accepted,
        "f_sim_p_invited": sim_p_invited,

        "is_top3": is_top3,
    }


# --------- RECOMMEND PARTNERS (HYBRID: RULE + ML) --------- #


def recommend_partners(
    me: UserDetails,
    others: List[UserDetails],
    limit: int = 10,
    offset: int = 0,
) -> List[MatchCandidate]:

    # 1) Tính rule-based score như cũ
    raw_candidates: List[MatchCandidate] = []

    for other in others:
        total_score, debug_details = compute_match_score(me, other, weights=DEFAULT_WEIGHTS)
        if total_score <= 0:
            continue

        raw_candidates.append(
            MatchCandidate(
                user=other,
                score=round(total_score, 2),
                debug_info=debug_details,
            )
        )

    # 2) Sort lần 1 theo rule_score → để lấy rank_in_list
    raw_candidates.sort(key=lambda c: c.score, reverse=True)

    final_candidates: List[MatchCandidate] = []

    for idx, c in enumerate(raw_candidates, start=1):
        rule_score = c.score
        debug_details = dict(c.debug_info or {})

        # Build feature cho ML
        feat = _build_logistic_regression_features_for_partner(
            me=me,
            other=c.user,
            rule_score=rule_score,
            rank_in_list=idx,
            debug_details=debug_details,
        )

        ml_prob = predict_accept_probability(feat)  # 0..1 hoặc None nếu lỗi

        if ml_prob is None:
            # fallback: chỉ dùng rule_score
            combined_score = rule_score
        else:
            # kết hợp: 70% rule + 30% ML (scaled 0..100)
            combined_score = 0.7 * rule_score + 0.3 * (ml_prob * 100.0)

        final_candidates.append(
            MatchCandidate(
                user=c.user,
                score=round(combined_score, 2),
                debug_info={
                    **debug_details,
                    "rule_score": rule_score,
                    "ml_prob": ml_prob,
                    "combined_score": combined_score,
                },
            )
        )

    # 3) Sort lần 2 theo combined_score
    final_candidates.sort(key=lambda c: c.score, reverse=True)
    if offset < 0:
        offset = 0

    if limit <= 0:
        return []

    return final_candidates[offset : offset + limit]


# --------- RECOMMEND FRIENDS (TẠM THỜI GIỮ NGUYÊN RULE-BASED) --------- #


def recommend_friends(
    me: UserDetails,
    others: List[UserDetails],
    limit: int = 10,
    offset: int = 0,
) -> List[MatchCandidate]:

    candidates: List[MatchCandidate] = []

    for other in others:
        score, details = compute_friend_score(me, other, weights=FRIEND_WEIGHTS)
        if score <= 0:
            continue

        candidates.append(
            MatchCandidate(
                user=other,
                score=round(score, 2),
                debug_info=details,
            )
        )

    candidates.sort(key=lambda c: c.score, reverse=True)
    if offset < 0:
        offset = 0

    if limit <= 0:
        return []

    return candidates[offset : offset + limit]
