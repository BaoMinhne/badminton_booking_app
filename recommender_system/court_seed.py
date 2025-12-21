"""
court_seed.py

Seed courts + managers + opening hours + court units + hourly pricing into PocketBase.

Collections expected:
- users (auth)
- courts
- court_opening_hours
- court_units
- court_pricing

Duplicate handling:
- Courts: duplicate if (name == ...) OR (location == ...) -> skip seeding for that court
- Users: reuse by email OR phone
- Opening hours: one per court (skip if exists)
- Court units: dedup by (court_id + court_num)
- Pricing: dedup by (court_id + time_from + time_to)

Phone generation:
- random VN mobile (10 digits starting with 0), ensure not used in users.phone or courts.phone.
"""

import asyncio
import random
import re
import unicodedata
from typing import Any, Dict, List, Optional, Set, Tuple

from pocketbase_client import create_record, get_list

# -----------------------
# Config
# -----------------------
DEFAULT_OPEN = "05:00"
DEFAULT_CLOSE = "23:00"

MANAGER_PASSWORD = "Ct@2025_Manager!"  # đổi sau khi seed

# Default hourly pricing (VND/hour) - adjust as needed
DEFAULT_PRICING = [
    {"time_from": "05:00", "time_to": "16:59", "price_per_hour": 60000},
    {"time_from": "17:00", "time_to": "23:00", "price_per_hour": 80000},
]

# VN mobile prefixes (10 digits total, starts with 0)
VN_PREFIXES = [
    "032", "033", "034", "035", "036", "037", "038", "039",
    "070", "076", "077", "078", "079",
    "081", "082", "083", "084", "085",
    "056", "058",
    "059",
    "090", "093", "089",
    "091", "094", "088",
    "096", "097", "098", "086",
]

_generated_phones: Set[str] = set()


# -----------------------
# Helpers
# -----------------------
def normalize_text(s: str) -> str:
    if not s:
        return ""
    s = unicodedata.normalize("NFKD", s)
    s = "".join(ch for ch in s if not unicodedata.combining(ch))
    s = s.lower().strip()
    s = re.sub(r"\s+", " ", s)
    return s


def slugify(text: str) -> str:
    text = normalize_text(text)
    text = re.sub(r"[^a-z0-9]+", "", text)
    return text[:24] if len(text) > 24 else (text or "manager")


def escape_pb_str(s: str) -> str:
    return (s or "").replace("'", "\\'")


def build_code(prefix: str, name: str) -> str:
    s = normalize_text(name)
    s = re.sub(r"[^a-z0-9]+", "", s).upper()
    return f"{prefix}-{s}"


def build_manager_email(court_name: str, phone: str) -> str:
    """
    Ensure email uniqueness:
    manager.<slug>.<last4>@courts.local
    """
    slug = slugify(court_name)
    suffix = (phone or "0000")[-4:]
    return f"manager.{slug}.{suffix}@courts.local"


async def get_first_record(collection: str, filter_expr: str) -> Optional[Dict[str, Any]]:
    data = await get_list(collection, page=1, per_page=1, filter_expr=filter_expr)
    items = data.get("items", [])
    return items[0] if items else None


# -----------------------
# Random phone
# -----------------------
async def phone_exists_in_db(phone: str) -> bool:
    u = await get_list("users", page=1, per_page=1, filter_expr=f"phone = '{escape_pb_str(phone)}'")
    if u.get("items"):
        return True

    c = await get_list("courts", page=1, per_page=1, filter_expr=f"phone = '{escape_pb_str(phone)}'")
    if c.get("items"):
        return True

    return False


async def random_unique_phone() -> str:
    """
    Generate VN mobile phone number: 10 digits, starts with 0.
    Matches: ^(?:0|\\+84)\\d{9}$
    We generate 0xxxxxxxxx (10 digits) -> valid.
    """
    while True:
        prefix = random.choice(VN_PREFIXES)           # 3 digits (starts with 0)
        tail = f"{random.randint(0, 9999999):07d}"    # 7 digits
        phone = prefix + tail                         # total 10 digits

        if phone in _generated_phones:
            continue
        if await phone_exists_in_db(phone):
            continue

        _generated_phones.add(phone)
        return phone


# -----------------------
# Duplicate checks
# -----------------------
async def find_existing_court(name: str, location: str) -> Optional[Dict[str, Any]]:
    safe_name = escape_pb_str(name)
    safe_loc = escape_pb_str(location)
    data = await get_list(
        "courts",
        page=1,
        per_page=1,
        filter_expr=f"(name = '{safe_name}') || (location = '{safe_loc}')",
    )
    items = data.get("items", [])
    return items[0] if items else None


# -----------------------
# Ensure manager user
# -----------------------
async def find_existing_user_by_phone(phone: str) -> Optional[Dict[str, Any]]:
    if not phone:
        return None
    return await get_first_record("users", f"phone = '{escape_pb_str(phone)}'")


async def find_existing_user_by_email(email: str) -> Optional[Dict[str, Any]]:
    if not email:
        return None
    return await get_first_record("users", f"email = '{escape_pb_str(email)}'")


async def ensure_manager_user(court_name: str, phone: str) -> Tuple[str, Dict[str, Any], bool]:
    """
    Reuse user by email OR phone. Otherwise create new.
    """
    uname = slugify(court_name)
    email = build_manager_email(court_name, phone)

    existing = await find_existing_user_by_email(email)
    if not existing:
        existing = await find_existing_user_by_phone(phone)

    if existing:
        return existing["id"], existing, False

    payload = {
        "email": email,
        "emailVisibility": False,
        "verified": False,
        "password": MANAGER_PASSWORD,
        "passwordConfirm": MANAGER_PASSWORD,
        "username": uname,
        "phone": phone,
        "role": "manager",
    }
    created = await create_record("users", payload)
    return created["id"], created, True


# -----------------------
# Create court & related
# -----------------------
async def create_court_record(
    *,
    name: str,
    code: str,
    phone: str,
    location: str,
    description: str,
    court_quantity: int,
    owner_user_id: str,
) -> Dict[str, Any]:
    payload = {
        "name": name,
        "code": code,
        "phone": phone,
        "location": location,
        "description": description,
        "court_quantity": int(court_quantity),
        "is_active": True,
        "owner": owner_user_id,
    }
    return await create_record("courts", payload)


async def ensure_opening_hours(court_id: str) -> Optional[Dict[str, Any]]:
    existing = await get_first_record("court_opening_hours", f"court_id = '{escape_pb_str(court_id)}'")
    if existing:
        return None
    payload = {"court_id": court_id, "open_time": DEFAULT_OPEN, "close_time": DEFAULT_CLOSE}
    return await create_record("court_opening_hours", payload)


async def ensure_court_units(court_id: str, court_quantity: int) -> int:
    created = 0
    for i in range(1, int(court_quantity) + 1):
        existing = await get_first_record(
            "court_units",
            f"court_id = '{escape_pb_str(court_id)}' && court_num = {i}",
        )
        if existing:
            continue

        payload = {"court_id": court_id, "court_num": i, "court_label": f"Sân {i}", "is_active": True}
        await create_record("court_units", payload)
        created += 1
    return created


async def ensure_hourly_pricing(
    court_id: str,
    pricing_rows: List[Dict[str, Any]],
) -> int:
    """
    Create court_pricing rows, dedup by court_id + time_from + time_to
    Expected fields:
      - court_id
      - time_from (HH:MM)
      - time_to (HH:MM)
      - price_per_hour (number or string)
    """
    created = 0
    for row in pricing_rows:
        tf = str(row["time_from"]).strip()
        tt = str(row["time_to"]).strip()
        price = row["price_per_hour"]

        existing = await get_first_record(
            "court_pricing",
            f"court_id = '{escape_pb_str(court_id)}' && time_from = '{escape_pb_str(tf)}' && time_to = '{escape_pb_str(tt)}'",
        )
        if existing:
            continue

        payload = {
            "court_id": court_id,
            "time_from": tf,
            "time_to": tt,
            "price_per_hour": price,
        }
        await create_record("court_pricing", payload)
        created += 1

    return created


# -----------------------
# Courts data
# (Bạn có thể thêm field 'pricing' riêng cho từng sân nếu muốn override)
# -----------------------
COURTS: List[Dict[str, Any]] = [
    # Ninh Kiều / lân cận trung tâm
    {"name": "Sân Cầu Lông Hoàng Long", "location": "393/5 Khu Vực 6, An Khánh, Ninh Kiều, Cần Thơ", "court_quantity": 8, "description": ""},
    {"name": "Sân cầu lông Hồng Phát / Hợp Lực", "location": "34 Trần Hoàng Na, An Khánh, Ninh Kiều, Cần Thơ", "court_quantity": 3, "description": ""},
    {"name": "Sân Cầu Lông 116 & Pickleball", "location": "116 Đường 3 Tháng 2, Xuân Khánh, Ninh Kiều, Cần Thơ", "court_quantity": 4, "description": ""},
    {"name": "Sân cầu lông ĐK", "location": "295 Nguyễn Văn Linh, Long Hòa, Cần Thơ", "court_quantity": 9, "description": ""},
    {"name": "Nhà thi đấu cũ – Đại học Cần Thơ", "location": "Khu Đại học Cần Thơ, Xuân Khánh, Ninh Kiều, Cần Thơ (mã vị trí 2QJ9+WF3/2QJ9+V8R)", "court_quantity": 4, "description": ""},
    {"name": "Sân Cầu Lông ĐHCT", "location": "Khu Đại học Cần Thơ, Xuân Khánh, Ninh Kiều, Cần Thơ", "court_quantity": 4, "description": ""},
    {"name": "Sân Cầu Lông Cao Đẳng Cần Thơ", "location": "57 Lê Lợi, Cái Khế, Ninh Kiều, Cần Thơ", "court_quantity": 3, "description": ""},
    {"name": "Sân cầu lông Nhà Văn Hóa Lao Động TP. Cần Thơ", "location": "Lê Lợi/57 bờ kè sông Hậu, Cái Khế, Ninh Kiều, Cần Thơ", "court_quantity": 2, "description": ""},
    {"name": "Sân Cầu Lông Cao Đẳng Kinh Tế Kỹ Thuật", "location": "9 Cách Mạng Tháng 8, An Hòa, Ninh Kiều, Cần Thơ", "court_quantity": 6, "description": ""},

    # Cái Răng
    {"name": "Sân cầu lông Phúc Cần Thơ", "location": "Khu 586, Cái Răng, Cần Thơ", "court_quantity": 4, "description": ""},
    {"name": "Sân cầu lông Huy Hoàng", "location": "54 Trần Chiên, Lê Bình, Cái Răng, Cần Thơ", "court_quantity": 2, "description": ""},
    {"name": "Sân Cầu Lông Win Sport", "location": "21 Phạm Hùng, Ba Láng, Cái Răng, Cần Thơ", "court_quantity": 6, "description": ""},
    {"name": "Sân Cầu Lông Bạn Ơi", "location": "454/315 Trương Vĩnh Nguyên, Phú Thứ, Cái Răng, Cần Thơ", "court_quantity": 3, "description": ""},
    {"name": "Sân Cầu Lông Hưng Lợi", "location": "Võ Nguyên Giáp, Phú Thứ, Cái Răng, Cần Thơ (mã 2Q8G+9JX)", "court_quantity": 7, "description": ""},
    {"name": "FWB – Badminton", "location": "234 Trần Hưng Đạo nối dài, Lê Bình, Cái Răng, Cần Thơ", "court_quantity": 3, "description": ""},

    # Bình Thủy
    {"name": "Sân cầu lông Nguyễn Thông", "location": "192/96 Nguyễn Thông, An Thới, Bình Thủy, Cần Thơ", "court_quantity": 3, "description": ""},
    {"name": "Sân Cầu Lông Bà Bộ", "location": "Làng Hoa Phó Thọ, Bà Bộ, Bình Thủy, Cần Thơ", "court_quantity": 6, "description": ""},
    {"name": "Sân Cầu Lông Ngân Thuận", "location": "KDT Mega Stella City, Bình Thủy, Cần Thơ", "court_quantity": 4, "description": ""},

    # Cồn Khương / Cái Khế
    {"name": "Sân Cầu Lông Cồn Khương", "location": "Cuối đường Trần Văn Giàu, Cái Khế, Ninh Kiều, Cần Thơ", "court_quantity": 6, "description": ""},
    {"name": "Sân Cầu Lông Like Cồn Khương", "location": "Đường số 1, Cái Khế, Ninh Kiều, Cần Thơ", "court_quantity": 6, "description": ""},

    # Huyện
    {"name": "Sân Cầu lông Luận", "location": "85 ĐT922, TT. Cờ Đỏ, Cờ Đỏ, Cần Thơ", "court_quantity": 7, "description": ""},
    {"name": "Sân Cầu Lông Như Ý", "location": "Trường Thắng, Thới Lai, Cần Thơ", "court_quantity": 2, "description": ""},
]


# -----------------------
# Seed
# -----------------------
async def seed_one(c: Dict[str, Any]) -> Tuple[bool, str]:
    name = (c.get("name") or "").strip()
    location = (c.get("location") or "").strip()
    qty = int(c.get("court_quantity") or 0)
    description = (c.get("description") or "").strip()

    if not name or not location or qty <= 0:
        return False, f"[SKIP][INVALID] name/location/qty missing: {c}"

    existing = await find_existing_court(name, location)
    if existing:
        return False, f"[SKIP][DUP_COURT] {name} | {location} | id={existing.get('id')}"

    # Always randomize phone for manager+court
    phone = await random_unique_phone()

    # Manager
    manager_id, manager_rec, created_user = await ensure_manager_user(name, phone)
    user_tag = "CREATED" if created_user else "REUSED"

    # Court
    code = build_code("CT", name)
    court_rec = await create_court_record(
        name=name,
        code=code,
        phone=phone,
        location=location,
        description=description,
        court_quantity=qty,
        owner_user_id=manager_id,
    )
    court_id = court_rec["id"]

    # Opening hours
    oh = await ensure_opening_hours(court_id)
    oh_tag = "CREATED" if oh else "SKIP_EXISTS"

    # Units
    units_created = await ensure_court_units(court_id, qty)

    # Pricing (use per-court override if provided, else DEFAULT_PRICING)
    pricing_rows = c.get("pricing") or DEFAULT_PRICING
    pricing_created = await ensure_hourly_pricing(court_id, pricing_rows)

    return True, (
        f"[OK] {name}\n"
        f"  - manager({user_tag}): id={manager_id}, email={manager_rec.get('email')}, phone={phone}\n"
        f"  - court(CREATED): id={court_id}, code={code}, qty={qty}\n"
        f"  - opening_hours({oh_tag}): {DEFAULT_OPEN}-{DEFAULT_CLOSE}\n"
        f"  - court_units(created={units_created}/{qty})\n"
        f"  - pricing(created={pricing_created}/{len(pricing_rows)})"
    )


async def main() -> None:
    created = 0
    skipped = 0

    for c in COURTS:
        ok, msg = await seed_one(c)
        print(msg)
        if ok:
            created += 1
        else:
            skipped += 1

    print("\n---- DONE ----")
    print(f"created={created}, skipped={skipped}")


if __name__ == "__main__":
    asyncio.run(main())
