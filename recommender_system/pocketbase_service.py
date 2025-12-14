# pocketbase_service.py
from typing import Any, Dict, List, Optional

from   pocketbase_client import create_record, update_record, get_list, delete_record

from datetime import datetime, timezone

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
    

async def delete_recommendation_logs(
    filter_expr: Optional[str] = None,
    batch_size: int = 200,
) -> int:
    """
    Xóa các record trong recommendation_logs.
    - Nếu filter_expr = None  -> xóa tất cả.
    - Nếu có filter_expr      -> chỉ xóa các record match filter đó.
    Trả về: số record đã xóa.
    """
    total_deleted = 0
    page = 1

    while True:
        data = await get_list(
            "recommendation_logs",
            page=page,
            per_page=batch_size,
            filter_expr=filter_expr,
        )
        items = data.get("items", [])
        if not items:
            break

        for rec in items:
            try:
                await delete_record("recommendation_logs", rec["id"])
                total_deleted += 1
            except Exception as e:
                print("[DELETE_RECO_LOG][ERROR]", rec.get("id"), e)

        # Nếu số item ít hơn batch_size thì không còn trang tiếp theo
        if len(items) < batch_size:
            break

        page += 1

    return total_deleted


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


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


async def mark_recommendation_shown(
    *,
    from_user_id: str,
    to_user_id: str,
    session_id: str,
    rank_shown: int,
) -> None:
    """
    UI gọi khi danh sách gợi ý đã được render.
    Update record gần nhất: shown=true, shown_at, session_id, rank_shown
    """
    rec = await _get_latest_recommendation_log(from_user_id, to_user_id)
    if not rec:
        return

    await update_record(
        "recommendation_logs",
        rec["id"],
        {
            "shown": True,
            "shown_at": _now_iso(),
            "session_id": session_id,
            "rank_shown": rank_shown,
        },
    )


async def mark_recommendation_clicked_profile(
    *,
    from_user_id: str,
    to_user_id: str,
) -> None:
    """
    UI gọi khi user click xem hồ sơ một gợi ý.
    """
    rec = await _get_latest_recommendation_log(from_user_id, to_user_id)
    if not rec:
        return

    await update_record(
        "recommendation_logs",
        rec["id"],
        {"clicked_profile": True},
    )


async def mark_recommendation_dismissed(
    *,
    from_user_id: str,
    to_user_id: str,
    reason: str | None = None,
) -> None:
    """
    UI gọi khi user bấm 'Không quan tâm/Ẩn gợi ý'.
    Theo schema mới: rejected=true, responded=true, responded_at, features.reason
    """
    rec = await _get_latest_recommendation_log(from_user_id, to_user_id)
    if not rec:
        return

    # patch features để lưu reason (nếu có)
    features = rec.get("features") or {}
    if not isinstance(features, dict):
        features = {}
    if reason:
        features["dismiss_reason"] = reason

    await update_record(
        "recommendation_logs",
        rec["id"],
        {
            "rejected": True,
            "responded": True,
            "responded_at": _now_iso(),
            "features": features,
        },
    )


async def mark_recommendation_outcome(
    *,
    from_user_id: str,
    to_user_id: str,
    outcome: str,  # "accepted" | "rejected" | "ignored"
) -> None:
    """
    Log trạng thái phản hồi cuối:
    - accepted: accepted=true, responded=true
    - rejected: rejected=true, responded=true
    - ignored : responded=false (hoặc true tùy định nghĩa), ghi features.response
    """
    rec = await _get_latest_recommendation_log(from_user_id, to_user_id)
    if not rec:
        return

    features = rec.get("features") or {}
    if not isinstance(features, dict):
        features = {}
    features["response"] = outcome

    patch: Dict[str, Any] = {
        "features": features,
        "responded_at": _now_iso(),
    }

    if outcome == "accepted":
        patch.update({"accepted": True, "rejected": False, "responded": True})
    elif outcome == "rejected":
        patch.update({"accepted": False, "rejected": True, "responded": True})
    else:  # ignored
        patch.update({"accepted": False, "rejected": False, "responded": False})

    await update_record("recommendation_logs", rec["id"], patch)