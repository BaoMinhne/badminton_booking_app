"""
generate_advanced_interactions.py

Phiên bản ADVANCED mô phỏng hành vi người dùng cho hệ thống gợi ý.

Ý tưởng:
1. Lấy danh sách user thực từ PocketBase (collection user_details).
2. Với mỗi user, gọi API FastAPI:
      - /recommend/players
      - /recommend/friends
   => app.py sẽ tự tạo recommendation_logs đúng chuẩn rule-based.
3. Sau đó đọc recommendation_logs, với MỖI record:
   - Tính xác suất invited/accepted dựa trên:
       + rule_score
       + rank_in_list
       + "synergy" (style + intensity + role)
   - Random invite/accept theo xác suất đó.
   - Một phần accepted sẽ sinh thêm match_feedback good/ok/bad.
   - Đánh dấu features['synthetic_version'] = 'v2_advanced'
     để lần sau script không đụng lại record cũ.

Chạy:
    (myenv) python generate_advanced_interactions.py \
        --rounds 50 \
        --max-logs 5000 \
        --feedback-ratio 0.4

YÊU CẦU:
- .env đã cấu hình cho PocketBase (POCKETBASE_URL, PB_USER_EMAIL, PB_USER_PASSWORD)
- FastAPI đang chạy (uvicorn app:app --reload)
- ĐÃ cài aiohttp:  pip install aiohttp
"""

import argparse
import asyncio
import random
from typing import Any, Dict, List, Tuple
from typing import List  # nhớ import ở đầu file


import aiohttp

from pocketbase_client import ensure_user_login, get_list, update_record
from pocketbase_service import create_match_feedback

# ĐỔI URL NÀY THEO MÔI TRƯỜNG CỦA BẠN
# - Nếu chạy cùng máy với FastAPI:  http://127.0.0.1:8000
# - Nếu gọi từ container khác, chỉnh IP phù hợp.
FASTAPI_BASE_URL = "http://127.0.0.1:8000"


# ---------------------------------------------------------------------
# UTILITIES: LẤY USER, LẤY LOG
# ---------------------------------------------------------------------


async def fetch_all_user_details() -> List[Dict[str, Any]]:
    """Lấy toàn bộ user_details để biết danh sách user_id."""
    await ensure_user_login()

    all_items: List[Dict[str, Any]] = []
    page = 1
    per_page = 200

    while True:
        data = await get_list(
            "user_details",
            page=page,
            per_page=per_page,
            filter_expr=None,
        )
        items = data.get("items", [])
        if not items:
            break
        all_items.extend(items)

        if len(items) < per_page:
            break

        page += 1

    print(f"[INFO] fetched {len(all_items)} user_details")
    return all_items


async def fetch_recommendation_logs(max_logs: int | None = None) -> List[Dict[str, Any]]:
    """Lấy recommendation_logs, có giới hạn max_logs nếu set."""
    await ensure_user_login()

    all_items: List[Dict[str, Any]] = []
    page = 1
    per_page = 200

    while True:
        remaining = None if max_logs is None else (max_logs - len(all_items))
        if remaining is not None and remaining <= 0:
            break

        page_size = per_page if remaining is None else min(per_page, remaining)

        data = await get_list(
            "recommendation_logs",
            page=page,
            per_page=page_size,
            filter_expr=None,
        )

        items = data.get("items", [])
        if not items:
            break

        all_items.extend(items)

        if len(items) < page_size:
            break

        page += 1

    print(f"[INFO] fetched {len(all_items)} recommendation_logs for simulation")
    return all_items


# ---------------------------------------------------------------------
# BƯỚC 1: GỌI API RECOMMEND ĐỂ TẠO LOG THẬT
# ---------------------------------------------------------------------


async def call_recommend_for_user(session: aiohttp.ClientSession, user_id: str) -> None:
    """Gọi ngẫu nhiên /recommend/players hoặc /recommend/friends cho 1 user."""
    mode = random.choice(["players", "friends"])
    endpoint = "/recommend/players" if mode == "players" else "/recommend/friends"
    url = f"{FASTAPI_BASE_URL}{endpoint}?user_id={user_id}&limit=20"

    try:
        async with session.get(url) as res:
            if res.status != 200:
                text = await res.text()
                print(f"[WARN] recommend {mode} failed for {user_id}: {res.status} {text}")
            else:
                print(f"[OK] recommend {mode} called for user {user_id}")
    except Exception as e:
        print(f"[ERROR] calling recommend for {user_id}: {e}")



async def generate_logs_by_calling_api(rounds: int) -> None:
    users = await fetch_all_user_details()

    # Ép kiểu rõ ràng cho Pylance
    user_ids: List[str] = [
        str(u["user_id"])
        for u in users
        if isinstance(u.get("user_id"), str) and u["user_id"]
    ]

    if len(user_ids) < 2:
        print("[ERROR] not enough users in user_details (need >= 2).")
        return

    async with aiohttp.ClientSession() as session:
        for i in range(rounds):
            uid: str = random.choice(user_ids)   # uid chắc chắn là str
            await call_recommend_for_user(session, uid)



# ---------------------------------------------------------------------
# BƯỚC 2: MÔ PHỎNG HÀNH VI NGƯỜI DÙNG TRÊN recommendation_logs
# ---------------------------------------------------------------------


def _extract_synergy(features: Dict[str, Any]) -> float:
    """
    Ước tính "synergy" dựa trên điểm level/style/role/intensity trong features.
    - Trong app.py, debug_info = dict(scores) với keys:
        'level', 'style', 'role', 'intensity', 'court', 'habit'
    - Tổng tối đa xấp xỉ 40 + 20 + 20 + 15 = 95 (bỏ court/habit).

    Ta chuẩn hóa về 0..1.
    """
    level = float(features.get("level", 0.0) or 0.0)
    style = float(features.get("style", 0.0) or 0.0)
    role = float(features.get("role", 0.0) or 0.0)
    intensity = float(features.get("intensity", 0.0) or 0.0)

    raw = level + style + role + intensity
    # giả sử tổng max ~95
    synergy = raw / 95.0 if raw > 0 else 0.0
    return max(0.0, min(1.0, synergy))


def _invited_probability(rule_score: float, rank_in_list: float, synergy: float) -> float:
    """
    Xác suất gửi lời mời:
    - cao khi score cao, rank cao (top), synergy tốt.
    """
    score_norm = max(0.0, min(1.0, rule_score / 100.0))
    rank_factor = max(0.2, 1.0 - (rank_in_list - 1) / 15.0)  # top 1~5 cao hơn
    synergy_factor = 0.5 + 0.5 * synergy  # 0.5..1.0

    base = 0.1 + 0.6 * score_norm          # 0.1..0.7
    invited_prob = base * rank_factor * synergy_factor  # 0..~0.7

    # giới hạn max 0.9 để vẫn còn random
    return max(0.01, min(0.9, invited_prob))


def _accepted_probability(
    rule_score: float,
    synergy: float,
    already_invited: bool,
) -> float:
    """
    Xác suất accept (điều kiện đã nhận được lời mời).
    - phụ thuộc nhiều vào score + synergy.
    """
    score_norm = max(0.0, min(1.0, rule_score / 100.0))

    base = 0.05 + 0.7 * score_norm  # 0.05..0.75
    synergy_factor = 0.4 + 0.6 * synergy  # 0.4..1.0

    prob = base * synergy_factor           # ~ 0..0.75
    if not already_invited:
        # nếu chưa từng invite, xác suất chấp nhận rất thấp
        prob *= 0.1

    return max(0.01, min(0.95, prob))


def _sample_feedback(rule_score: float, synergy: float) -> str:
    """
    Sinh feedback 'good' / 'ok' / 'bad' theo score + synergy.
    """
    score_norm = max(0.0, min(1.0, rule_score / 100.0))
    happiness = 0.5 * score_norm + 0.5 * synergy  # 0..1

    r = random.random()

    if happiness > 0.75:
        # rất hợp nhau: chủ yếu good, chút ok
        if r < 0.8:
            return "good"
        return "ok"

    if happiness > 0.4:
        # tạm ổn: nhiều ok, chút good/bad
        if r < 0.15:
            return "good"
        elif r < 0.75:
            return "ok"
        else:
            return "bad"

    # không hợp lắm: chủ yếu ok/bad
    if r < 0.2:
        return "ok"
    return "bad"


async def simulate_user_behavior_on_logs(
    max_logs: int | None = None,
    feedback_ratio: float = 0.4,
) -> None:
    """
    Đọc recommendation_logs và mô phỏng:
    - invited: True/False
    - accepted: True/False
    - match_feedback: good/ok/bad cho 1 phần accepted

    Chỉ áp dụng cho những record:
    - chưa có 'synthetic_version' trong features
    (để tránh ghi đè lần sau).
    """
    logs = await fetch_recommendation_logs(max_logs=max_logs)

    if not logs:
        print("[WARN] no recommendation_logs to simulate on.")
        return

    await ensure_user_login()

    total = 0
    updated_logs = 0
    created_feedback = 0

    for log in logs:
        total += 1
        features = log.get("features") or {}
        if not isinstance(features, dict):
            features = {}

        # bỏ qua record synthetic cũ (đã xử lý)
        if features.get("synthetic_version") == "v2_advanced":
            continue

        rule_score = float(log.get("rule_score") or 0.0)
        rank_in_list = float(log.get("rank_in_list") or 50.0)
        synergy = _extract_synergy(features)

        # xác suất invite & accept
        p_invited = _invited_probability(rule_score, rank_in_list, synergy)
        invited = random.random() < p_invited

        p_accepted = _accepted_probability(rule_score, synergy, invited)
        accepted = invited and (random.random() < p_accepted)

        # cập nhật features để đánh dấu synthetic
        features["synthetic_version"] = "v2_advanced"
        features["sim_p_invited"] = round(p_invited, 3)
        features["sim_p_accepted"] = round(p_accepted, 3)

        update_body: Dict[str, Any] = {
            "invited": invited,
            "accepted": accepted,
            "features": features,
        }

        try:
            await update_record("recommendation_logs", log["id"], update_body)
            updated_logs += 1
        except Exception as e:
            print(f"[WARN] cannot update recommendation_log {log.get('id')}: {e}")
            continue

        # Nếu accepted → có xác suất sinh thêm match_feedback
        if accepted and random.random() < feedback_ratio:
            from_user = log.get("from_user")
            to_user = log.get("to_user")
            if from_user and to_user:
                fb = _sample_feedback(rule_score, synergy)
                try:
                    await create_match_feedback(
                        from_user_id=from_user,
                        to_user_id=to_user,
                        booking_id=None,
                        feedback=fb,
                        comment=f"{fb}",
                    )
                    created_feedback += 1
                except Exception as e:
                    print(f"[WARN] cannot create match_feedback for log {log.get('id')}: {e}")

        if total % 100 == 0:
            print(
                f"[PROGRESS] processed {total}/{len(logs)} logs "
                f"(updated={updated_logs}, feedbacks={created_feedback})"
            )

    print(
        f"[DONE] simulate_user_behavior_on_logs: "
        f"processed={total}, updated={updated_logs}, "
        f"feedbacks={created_feedback}"
    )


# ---------------------------------------------------------------------
# ENTRYPOINT
# ---------------------------------------------------------------------


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate advanced synthetic interactions based on real recommend API.",
    )
    parser.add_argument(
        "--rounds",
        type=int,
        default=50,
        help="Số lượt gọi recommend API (mỗi lượt cho 1 user).",
    )
    parser.add_argument(
        "--max-logs",
        type=int,
        default=5000,
        help="Tối đa bao nhiêu recommendation_logs sẽ được mô phỏng hành vi.",
    )
    parser.add_argument(
        "--feedback-ratio",
        type=float,
        default=0.4,
        help="Tỉ lệ record accepted sinh thêm match_feedback (0..1).",
    )
    return parser.parse_args()


async def main() -> None:
    args = parse_args()
    print(f"[STEP 1] calling recommend APIs for {args.rounds} rounds ...")
    await generate_logs_by_calling_api(args.rounds)

    print(
        f"[STEP 2] simulating user behavior on recommendation_logs "
        f"(max_logs={args.max_logs}, feedback_ratio={args.feedback_ratio}) ..."
    )
    await simulate_user_behavior_on_logs(
        max_logs=args.max_logs,
        feedback_ratio=args.feedback_ratio,
    )


if __name__ == "__main__":
    asyncio.run(main())
