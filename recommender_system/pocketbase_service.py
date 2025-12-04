# pocketbase_service.py
from typing import Any, Dict, List, Optional

from   pocketbase_client import create_record, update_record, get_list


# ---------- USER_DETAILS ----------

async def get_user_details_by_user_id(user_id: str) -> Optional[dict]:
    data = await get_list(
        "user_details",
        page=1,
        per_page=1,
        filter_expr=f"user_id = '{user_id}'",
    )
    items = data.get("items", [])
    return items[0] if items else None


async def get_all_other_user_details(current_user_id: str, per_page: int = 200) -> List[dict]:
    data = await get_list(
        "user_details",
        page=1,
        per_page=per_page,
        filter_expr=f"user_id != '{current_user_id}'",
    )
    return data.get("items", [])


# ---------- RECOMMENDATION_LOGS ----------

async def create_recommendation_log(
    *,
    from_user_id: str,
    to_user_id: str,
    rule_score: float,
    rank_in_list: int,
    features: Optional[Dict[str, Any]] = None,
    invited: bool = False,
    accepted: bool = False,
) -> Dict[str, Any]:
    payload = {
        "from_user": from_user_id,
        "to_user": to_user_id,
        "rule_score": rule_score,
        "rank_in_list": rank_in_list,
        "features": features or {},
        "invited": invited,
        "accepted": accepted,
    }
    return await create_record("recommendation_logs", payload)


async def _get_latest_recommendation_log(from_user_id: str, to_user_id: str) -> Optional[Dict[str, Any]]:
    data = await get_list(
        "recommendation_logs",
        page=1,
        per_page=1,
        filter_expr=f'from_user = "{from_user_id}" && to_user = "{to_user_id}"',
        sort="-created",
    )
    items = data.get("items", [])
    return items[0] if items else None


async def mark_recommendation_invited(from_user_id: str, to_user_id: str) -> None:
    rec = await _get_latest_recommendation_log(from_user_id, to_user_id)
    if not rec:
        return
    await update_record("recommendation_logs", rec["id"], {"invited": True})


async def mark_recommendation_accepted(from_user_id: str, to_user_id: str) -> None:
    rec = await _get_latest_recommendation_log(from_user_id, to_user_id)
    if not rec:
        return
    await update_record("recommendation_logs", rec["id"], {"accepted": True})


# ---------- MATCH_FEEDBACK ----------

async def create_match_feedback(
    *,
    from_user_id: str,
    to_user_id: str,
    booking_id: Optional[str],
    feedback: str,
    comment: Optional[str] = None,
) -> Dict[str, Any]:
    payload: Dict[str, Any] = {
        "from_user": from_user_id,
        "to_user": to_user_id,
        "feedback": feedback,
    }
    if booking_id:
        payload["booking_id"] = booking_id
    if comment:
        payload["comment"] = comment

    return await create_record("match_feedback", payload)
