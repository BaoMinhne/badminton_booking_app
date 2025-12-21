# pocketbase_client.py
import os
from typing import Any, Dict, Optional

import httpx
from dotenv import load_dotenv

load_dotenv()

POCKETBASE_URL = os.getenv("POCKETBASE_URL", "http://127.0.0.1:8090")
PB_USER_EMAIL = os.getenv("PB_USER_EMAIL")
PB_USER_PASSWORD = os.getenv("PB_USER_PASSWORD")

client = httpx.AsyncClient(base_url=POCKETBASE_URL, timeout=10.0)
_auth_token: Optional[str] = None


async def ensure_user_login() -> None:
    global _auth_token
    if _auth_token is not None:
        return

    resp = await client.post(
        "/api/collections/users/auth-with-password",
        json={"identity": PB_USER_EMAIL, "password": PB_USER_PASSWORD},
    )
    resp.raise_for_status()
    _auth_token = resp.json()["token"]


def _auth_headers() -> Dict[str, str]:
    return {"Authorization": f"Bearer {_auth_token}"} if _auth_token else {}


async def create_record(collection: str, data: Dict[str, Any]) -> Dict[str, Any]:
    await ensure_user_login()
    resp = await client.post(
        f"/api/collections/{collection}/records",
        json=data,
        headers=_auth_headers(),
    )
    if resp.status_code >= 400:
        print("PB ERROR:", resp.status_code, resp.text)  # <<< thêm dòng này
    resp.raise_for_status()
    return resp.json()


async def update_record(collection: str, record_id: str, data: Dict[str, Any]) -> Dict[str, Any]:
    await ensure_user_login()
    resp = await client.patch(
        f"/api/collections/{collection}/records/{record_id}",
        json=data,
        headers=_auth_headers(),
    )
    resp.raise_for_status()
    return resp.json()


async def get_list(
    collection: str,
    page: int = 1,
    per_page: int = 30,
    *,
    filter_expr: Optional[str] = None,
    sort: Optional[str] = None,
) -> Dict[str, Any]:
    await ensure_user_login()
    params: Dict[str, Any] = {"page": page, "perPage": per_page}
    if filter_expr:
        params["filter"] = filter_expr
    if sort:
        params["sort"] = sort

    resp = await client.get(
        f"/api/collections/{collection}/records",
        params=params,
        headers=_auth_headers(),
    )
    resp.raise_for_status()
    return resp.json()


# ---------------------------------------------------------
# DELETE RECORD (CORRECT VERSION FOR HTTPX)
# ---------------------------------------------------------
async def delete_record(collection: str, record_id: str) -> bool:
    """
    Xóa 1 record trong collection bất kỳ bằng HTTP API.
    """
    await ensure_user_login()

    resp = await client.delete(
        f"/api/collections/{collection}/records/{record_id}",
        headers=_auth_headers(),
    )

    if resp.status_code >= 400:
        print(f"[PB][DELETE][ERROR] {collection}/{record_id} -> {resp.text}")
        resp.raise_for_status()

    return True
