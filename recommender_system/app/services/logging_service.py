from typing import List, Any, Dict

from app.models.match_candidate import MatchCandidate

from pocketbase_service import (
    create_recommendation_log,
)


async def log_recommendations(
    *,
    from_user_id: str,
    candidates: List[MatchCandidate],
    mode: str,  # "partner" | "friend"
) -> None:
    """
    Ghi log cho mỗi candidate vào collection recommendation_logs.
    """
    for index, c in enumerate(candidates, start=1):
        try:
            features: Dict[str, Any] = dict(c.debug_info or {})
            features["mode"] = mode

            await create_recommendation_log(
                from_user_id=from_user_id,
                to_user_id=c.user.user_id,
                rule_score=c.score,
                rank_in_list=index,
                features=features,
                invited=False,
                accepted=False,
            )
        except Exception as e:
            print(
                f"[RECO_LOG][ERROR] cannot log recommendation "
                f"{from_user_id} -> {c.user.user_id}: {e}"
            )
