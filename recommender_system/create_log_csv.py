import csv
import os
from pathlib import Path
import httpx
from typing import List, Dict, Any

from dotenv import load_dotenv

load_dotenv()

BASE_DIR = Path(__file__).resolve().parent
DATA_DIR = BASE_DIR / "data"

POCKETBASE_URL = os.getenv("POCKETBASE_URL", "http://127.0.0.1:8090")
PB_USER_EMAIL = os.getenv("PB_USER_EMAIL")
PB_USER_PASSWORD = os.getenv("PB_USER_PASSWORD")


async def login(client: httpx.AsyncClient) -> str:
    """Login và trả về token."""
    resp = await client.post(
        f"{POCKETBASE_URL}/api/collections/users/auth-with-password",
        json={"identity": PB_USER_EMAIL, "password": PB_USER_PASSWORD},
    )
    resp.raise_for_status()
    data = resp.json()
    return data["token"]


async def fetch_all_records(client: httpx.AsyncClient, collection: str) -> List[Dict[str, Any]]:
    """Lấy ALL records trong collection (bỏ qua phân trang, tự loop hết)."""
    page = 1
    per_page = 500
    all_items = []

    while True:
        resp = await client.get(
            f"{POCKETBASE_URL}/api/collections/{collection}/records",
            params={"page": page, "perPage": per_page},
            headers=client.headers,
        )
        resp.raise_for_status()
        data = resp.json()

        items = data.get("items", [])
        if not items:
            break

        all_items.extend(items)

        if page >= data["totalPages"]:
            break
        page += 1

    return all_items


def write_csv(filename: str, records: List[Dict[str, Any]]):
    """Ghi records thành file CSV."""
    if not records:
        print("Không có dữ liệu để export.")
        return

    DATA_DIR.mkdir(parents=True, exist_ok=True)

    target_path = DATA_DIR / filename

    # Lấy tất cả các key từ toàn bộ record
    fieldnames = set()
    for rec in records:
        fieldnames.update(rec.keys())

    fieldnames = sorted(list(fieldnames))

    with target_path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for rec in records:
            writer.writerow(rec)

    print(f"Đã export {len(records)} records → {target_path}")


# ----------------------
# ENTRY POINT
# ----------------------
import asyncio

async def main():
    async with httpx.AsyncClient() as client:
        token = await login(client)
        client.headers.update({"Authorization": f"Bearer {token}"})

        # ĐỔI collection name tại đây
        collection_name = "recommendation_logs"

        records = await fetch_all_records(client, collection_name)
        write_csv(f"{collection_name}.csv", records)

asyncio.run(main())
