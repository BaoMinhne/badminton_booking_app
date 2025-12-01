import os
from typing import List, Optional, Any

import httpx
from dotenv import load_dotenv

load_dotenv()

POCKETBASE_URL = os.getenv("POCKETBASE_URL", "http://127.0.0.1:8090")
PB_USER_EMAIL = os.getenv("PB_USER_EMAIL")
PB_USER_PASSWORD = os.getenv("PB_USER_PASSWORD")

if not PB_USER_EMAIL or not PB_USER_PASSWORD:
    raise RuntimeError("PB_USER_EMAIL or PB_USER_PASSWORD is not set in .env")

# Tạo 1 AsyncClient dùng chung
client = httpx.AsyncClient(base_url=POCKETBASE_URL, timeout=10.0)

_auth_token: Optional[str] = None


async def ensure_user_login() -> None:
    """
    Đăng nhập bằng user thường (auth collection `users`), lấy token để dùng cho các request sau.
    Gọi nhiều lần cũng không sao: nếu đã có token thì return luôn.
    """
    global _auth_token
    if _auth_token is not None:
        return

    resp = await client.post(
        "/api/collections/users/auth-with-password",
        json={
            "identity": PB_USER_EMAIL,
            "password": PB_USER_PASSWORD,
        },
    )
    resp.raise_for_status()
    data = resp.json()
    _auth_token = data["token"]
    # Nếu bạn thích dùng cookie thì có thể dùng resp.cookies, nhưng token là đủ.


def _auth_headers() -> dict[str, str]:
    if _auth_token is None:
        return {}
    return {"Authorization": f"Bearer {_auth_token}"}


async def get_user_details_by_user_id(user_id: str) -> Optional[dict]:
    """
    Lấy 1 record user_details theo user_id (id của _pb_users_auth_).
    """
    await ensure_user_login()

    resp = await client.get(
        "/api/collections/user_details/records",
        params={
            "filter": f"user_id = '{user_id}'",
            "perPage": 1,
        },
        headers=_auth_headers(),
    )
    resp.raise_for_status()
    data = resp.json()
    items = data.get("items", [])
    if not items:
        return None
    return items[0]


async def get_all_other_user_details(current_user_id: str, per_page: int = 200) -> List[dict]:
    """
    Lấy danh sách user_details của tất cả người dùng khác current_user_id.
    """
    await ensure_user_login()

    resp = await client.get(
        "/api/collections/user_details/records",
        params={
            "filter": f"user_id != '{current_user_id}'",
            "perPage": per_page,
        },
        headers=_auth_headers(),
    )
    resp.raise_for_status()
    data = resp.json()
    return data.get("items", [])
