"""
Script tạo 350 users + user_details giả lập trong PocketBase.

YÊU CẦU:
- PocketBase đang chạy (ví dụ: http://127.0.0.1:8090)
- Collection auth tên "users" (mặc định của PocketBase)
- Collection "user_details" như bạn đã thiết kế
- user_details hiện tại KHÔNG yêu cầu @request.auth.id trong createRule

LƯU Ý:
- Script này tạo user với email dạng: player_001@gmail.com, player_002@gmail.com, ...
- Mật khẩu mặc định cho tất cả: minh1234
- Mặc định role của các user mới = "user".
- NÊN chỉ chạy 1 lần, nếu chạy lại sẽ bị trùng email/username (PocketBase báo lỗi 400 cho những cái trùng).
"""

import os
import random
import string
from datetime import datetime, timedelta

import httpx
from dotenv import load_dotenv

load_dotenv()

POCKETBASE_URL = os.getenv("POCKETBASE_URL", "http://127.0.0.1:8090")
TOTAL_USERS = 340
DEFAULT_PASSWORD = "minh1234"  # bạn có thể đổi nếu muốn

# ------------------ TÊN HỌ VIỆT NAM ------------------ #

LAST_NAMES = [
    "Nguyễn", "Trần", "Lê", "Phạm", "Hoàng", "Khúc",
    "Vũ", "Đỗ", "Bùi", "Đặng", "Lý", "Hồ", "Võ",
    "Ngô", "Trịnh", "Đinh", "Văn",
]

MALE_NAMES = [
    "An", "Bảo", "Hùng", "Minh", "Khang", "Dũng", "Quân",
    "Nam", "Phúc", "Tùng", "Tuấn", "Sơn", "Hải", "Cường",
    "Long", "Hiếu", "Trung", "Thắng", "Phong", "Thiện",
]

FEMALE_NAMES = [
    "Linh", "Trang", "Vy", "Thảo", "Hà", "Quỳnh", "Yến",
    "Hương", "Lan", "Chi", "Thùy", "Nhung", "Mai", "Nhi",
    "Ngọc", "My", "Tiên", "Hạnh", "Phương", "Giang",
]


def random_fullname(gender: str) -> str:
    """
    Sinh fullname phù hợp với giới tính:
    - Họ random trong LAST_NAMES
    - Tên random trong MALE_NAMES / FEMALE_NAMES
    """
    last = random.choice(LAST_NAMES)
    if gender == "male":
        first = random.choice(MALE_NAMES)
    else:
        first = random.choice(FEMALE_NAMES)
    return f"{last} {first}"


# ------------------ RANDOM HELPERS ------------------ #

def random_phone() -> str:
    # Số VN fake với nhiều đầu số phổ biến
    prefix = random.choice([
        "090", "091", "092", "093", "094", "096", "097", "098", "099",
        "032", "033", "034", "035", "036", "037", "038", "039",
        "070", "079", "077", "076", "078",
        "083", "084", "085", "081", "082",
        "056", "058",
    ])
    middle = "".join(random.choices(string.digits, k=3))
    last = "".join(random.choices(string.digits, k=4))
    return f"{prefix}{middle}{last}"


def random_gender() -> str:
    return random.choice(["male", "female"])


def random_birthday() -> str:
    # Sinh người từ 18 đến 42 tuổi
    today = datetime.utcnow()
    min_age = 18
    max_age = 42
    age = random.randint(min_age, max_age)
    # random thêm vài tháng/ngày
    days_offset = random.randint(0, 365)
    birth_date = today - timedelta(days=age * 365 + days_offset)
    # PocketBase date kiểu: "YYYY-MM-DD 12:00:00.000Z"
    return birth_date.strftime("%Y-%m-%d 12:00:00.000Z")


def random_level_numeric() -> int:
    """
    Phân bố level thực tế hơn:
    1: Beginner           ~20%
    2: Lower Intermediate ~35%
    3: Intermediate       ~30%
    4: Upper Intermediate ~10%
    5: Advanced           ~5%
    """
    r = random.random()
    if r < 0.20:
        return 1          # 0.00 - 0.20
    elif r < 0.55:
        return 2          # 0.20 - 0.55 (35%)
    elif r < 0.85:
        return 3          # 0.55 - 0.85 (30%)
    elif r < 0.95:
        return 4          # 0.85 - 0.95 (10%)
    else:
        return 5          # 0.95 - 1.00 (5%)


def map_level_text(level_numeric: int) -> str:
    if level_numeric == 1:
        return "Beginner"
    if level_numeric == 2:
        return "Lower Intermediate"
    if level_numeric == 3:
        return "Intermediate"
    if level_numeric == 4:
        return "Upper Intermediate"
    return "Advanced"


def random_match_types():
    base = ["singles", "doubles", "mixed"]
    # chọn 1–3 kiểu
    k = random.randint(1, 3)
    return random.sample(base, k)


def random_play_style_tags():
    base = ["attack", "defense", "net", "baseline", "all_round", "fun", "competitive"]
    # chọn 1–4 tag
    k = random.randint(1, 4)
    return random.sample(base, k)


def random_preferred_role():
    return random.choice(["front", "back", "flexible"])


def random_intensity():
    # có thể bias theo level nếu muốn, tạm random đều
    return random.choice(["casual", "semi_competitive", "competitive"])


def random_experience_years(level_numeric: int) -> int:
    """
    Trả về SỐ NGUYÊN (PocketBase field đang onlyInt).
    """
    if level_numeric <= 2:
        return random.randint(1, 3)
    elif level_numeric == 3:
        return random.randint(2, 6)
    elif level_numeric == 4:
        return random.randint(4, 10)
    else:
        return random.randint(6, 15)


def random_plays_per_week(level_numeric: int) -> int:
    if level_numeric <= 2:
        return random.randint(1, 3)
    elif level_numeric == 3:
        return random.randint(2, 5)
    elif level_numeric == 4:
        return random.randint(3, 6)
    else:
        return random.randint(4, 7)


# ------------------ COURTS HELPERS ------------------ #

async def fetch_court_ids(client: httpx.AsyncClient) -> list[str]:
    """
    Lấy danh sách id các sân trong collection `courts`.
    Do listRule của courts là `is_active = true` nên chỉ trả về sân đang active.
    """
    court_ids: list[str] = []

    # Lấy tối đa 200 sân, nếu bạn có nhiều hơn có thể lặp trang sau này
    resp = await client.get("/api/collections/courts/records", params={"perPage": 200})
    if resp.status_code >= 400:
        print(f"[WARN] Failed to fetch courts: {resp.status_code} {resp.text}")
        return court_ids

    data = resp.json()
    items = data.get("items", [])
    for item in items:
        cid = item.get("id")
        if isinstance(cid, str):
            court_ids.append(cid)

    print(f"[INFO] Fetched {len(court_ids)} courts from PocketBase")
    return court_ids


# ------------------ USER & USER_DETAILS ------------------ #

async def create_auth_user(client: httpx.AsyncClient, index: int) -> dict | None:
    """
    Tạo 1 user auth trong collection "users".
    Trả về record user (dict) nếu thành công, None nếu lỗi (ví dụ trùng email).
    """
    username = f"player_{index:03d}"
    email = f"{username}@gmail.com"
    phone = random_phone()

    payload = {
        "email": email,
        "password": DEFAULT_PASSWORD,
        "passwordConfirm": DEFAULT_PASSWORD,
        "username": username,
        "phone": phone,   # nếu trong schema users của bạn có field phone
        "role": "user",   # set role mặc định là "user"
    }

    try:
        resp = await client.post("/api/collections/users/records", json=payload)
        if resp.status_code >= 400:
            print(f"[WARN] Failed to create user {email}: {resp.status_code} {resp.text}")
            return None
        data = resp.json()
        print(f"[OK] Created user: {email} (id={data.get('id')})")
        return data
    except Exception as e:
        print(f"[ERROR] Exception when creating user {email}: {e}")
        return None


async def create_user_details(
    client: httpx.AsyncClient,
    user_record: dict,
    court_ids: list[str],
) -> None:
    """
    Tạo record user_details cho user đã cho.
    - Không cần token vì createRule của user_details hiện không yêu cầu auth
    - Gán home_court = random 1 sân trong courts (nếu có)
    """
    user_id = user_record.get("id")
    if not user_id:
        print("[WARN] Missing user id in user_record")
        return

    # random giới tính trước để fullname khớp với gender
    gender = random_gender()
    fullname = random_fullname(gender)

    level_numeric = random_level_numeric()
    level_text = map_level_text(level_numeric)

    payload = {
        "user_id": user_id,
        "fullname": fullname,
        "gender": gender,
        "birthday": random_birthday(),
        "level_numeric": level_numeric,
        "level": level_text,
        "match_types": random_match_types(),
        "play_style_tags": random_play_style_tags(),
        "preferred_role_doubles": random_preferred_role(),
        "intensity": random_intensity(),
        "experience_years": random_experience_years(level_numeric),  # int
        "plays_per_week": random_plays_per_week(level_numeric),      # int
    }

    # Nếu có courts thì random gán home_court
    if court_ids:
        payload["home_court"] = random.choice(court_ids)

    try:
        resp = await client.post(
            "/api/collections/user_details/records",
            json=payload,
        )
        if resp.status_code >= 400:
            print(
                f"[WARN] Failed to create user_details for {user_id}: "
                f"{resp.status_code} {resp.text}"
            )
        else:
            data = resp.json()
            print(f"[OK] Created user_details for {user_id} (id={data.get('id')})")
    except Exception as e:
        print(f"[ERROR] Exception when creating user_details for {user_id}: {e}")


# ------------------ MAIN ------------------ #

async def main():
    print(f"POCKETBASE_URL = {POCKETBASE_URL}")
    async with httpx.AsyncClient(base_url=POCKETBASE_URL, timeout=15.0) as client:
        # 1. Lấy danh sách courts trước
        court_ids = await fetch_court_ids(client)
        if not court_ids:
            print("[WARN] No courts found. home_court sẽ để trống cho toàn bộ user_details.")

        created_count = 0
        for i in range(1, TOTAL_USERS + 1):
            user_record = await create_auth_user(client, i)
            if not user_record:
                continue

            await create_user_details(client, user_record, court_ids)
            created_count += 1

        print(f"\nDONE. Created approximately {created_count} users + user_details.")


if __name__ == "__main__":
    import asyncio

    asyncio.run(main())
