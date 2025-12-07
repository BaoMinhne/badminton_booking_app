from typing import Optional

from fastapi import APIRouter, HTTPException

from pocketbase_service import delete_recommendation_logs

router = APIRouter(prefix="/admin", tags=["admin"])


@router.delete("/recommendation-logs")
async def admin_clear_recommendation_logs(
    secret: str,
    from_user_id: Optional[str] = None,
    to_user_id: Optional[str] = None,
):
    """
    XÓA DỮ LIỆU recommendation_logs ĐỂ CHUẨN HÓA LẠI.

    - BẮT BUỘC truyền secret để tránh gọi nhầm.
    - Có thể truyền thêm:
        + from_user_id: chỉ xóa log mà user này là người được gợi ý danh sách.
        + to_user_id  : chỉ xóa log mà user này là người được gợi ý (candidate).
    - Nếu không truyền from_user_id/to_user_id -> xóa TẤT CẢ.
    """

    if secret != "dev-secret":  # TODO: đổi sang ENV
        raise HTTPException(status_code=403, detail="Forbidden")

    conditions = []
    if from_user_id:
        conditions.append(f"from_user = '{from_user_id}'")
    if to_user_id:
        conditions.append(f"to_user = '{to_user_id}'")

    filter_expr: Optional[str] = None
    if conditions:
        filter_expr = " && ".join(conditions)

    try:
        deleted = await delete_recommendation_logs(filter_expr=filter_expr)
        return {
            "status": "ok",
            "deleted": deleted,
            "filter": filter_expr or "ALL",
        }
    except Exception as e:
        print("[ADMIN_CLEAR_RECO_LOGS][ERROR]", e)
        raise HTTPException(status_code=500, detail="Cannot clear recommendation_logs")
