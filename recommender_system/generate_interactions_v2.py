"""
generate_advanced_interactions_v4.py

Phiên bản V4 (SESSION + FUNNEL) để seed lại dữ liệu tương tác cho hệ thống gợi ý, với các nút chỉnh
để giảm lệch nhãn (Accepted quá ít) và tạo dữ liệu "đúng funnel".

Mục tiêu:
- Giống hành vi thật: Shown -> Click -> (Dismiss hoặc Invite) -> (Accept/Reject/Ignore) -> Feedback (một phần)
- Có position bias (top được xem/click nhiều hơn)
- Có cá tính người dùng (invite_bias/accept_bias khác nhau)
- Có quota hành động mỗi session
- Outcome phụ thuộc người nhận (receiver bias) để tránh "rule -> nhãn"
- Có SEED cố định để tái lập dữ liệu
- Có các tham số để tăng/giảm Invite và Accept hợp lý

Chạy ví dụ:
    (myenv) python generate_advanced_interactions_v4.py --rounds 200 --feedback-ratio 0.4 --seed 42 \
        --min-invites 1 --invite-cap 4 --ignore-rate 0.10 --invite-boost 1.25 --accept-boost 1.15

YÊU CẦU:
- .env cấu hình PocketBase (POCKETBASE_URL, PB_USER_EMAIL, PB_USER_PASSWORD)
- FastAPI đang chạy (uvicorn app:app --reload)
- aiohttp: pip install aiohttp

Ghi chú quan trọng về dataset imbalance:
- Nếu bạn train "accept model" thì nên lọc dataset chỉ trên log invited=True.
- Script này giúp tăng số log invited/accepted nhưng vẫn giữ tính funnel.
"""

import argparse
import asyncio
import math
import random
import uuid
from datetime import datetime, timezone
from typing import Any, Dict, List, Tuple

import aiohttp

from pocketbase_client import ensure_user_login, get_list, update_record
from pocketbase_service import create_match_feedback

FASTAPI_BASE_URL = "http://127.0.0.1:8000"


# ---------------------------------------------------------------------
# UTILS
# ---------------------------------------------------------------------

def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()

def _sigmoid(x: float) -> float:
    return 1.0 / (1.0 + math.exp(-x))

def _clamp(x: float, lo: float, hi: float) -> float:
    return max(lo, min(hi, x))

def _exposure_probability(rank: int) -> float:
    """
    Position bias / exposure: rank càng cao càng được nhìn.
    rank 1 ~ 0.95, rank 5 ~ ~0.70, rank 10 ~ ~0.35, rank 20 ~ ~0.10
    """
    r = max(1, int(rank))
    p = 1.0 / (1.0 + (r / 5.0) ** 1.7)
    return _clamp(p, 0.02, 0.98)


def _extract_synergy(features: Dict[str, Any]) -> float:
    """
    Synergy dựa trên debug score: level/style/role/intensity (0..~95) -> normalize 0..1
    """
    level = float(features.get("level", 0.0) or 0.0)
    style = float(features.get("style", 0.0) or 0.0)
    role = float(features.get("role", 0.0) or 0.0)
    intensity = float(features.get("intensity", 0.0) or 0.0)

    raw = level + style + role + intensity
    synergy = raw / 95.0 if raw > 0 else 0.0
    return _clamp(synergy, 0.0, 1.0)


def _build_user_propensity(
    users: List[Dict[str, Any]],
    *,
    invite_cap: int,
) -> Dict[str, Dict[str, float]]:
    """
    Sinh cá tính mỗi user dựa trên user_details (nếu có).
    - invite_bias: xu hướng gửi lời mời (0.6..1.6)
    - accept_bias: xu hướng chấp nhận (0.6..1.6)
    - quota: số invite tối đa mỗi session (1..invite_cap)
    """
    prop: Dict[str, Dict[str, float]] = {}
    for u in users:
        uid = u.get("user_id")
        if not isinstance(uid, str) or not uid:
            continue

        # Các field có thể khác nhau tùy schema; fallback nếu thiếu
        habit = float(u.get("plays_per_week") or u.get("habit_per_week") or 2.0)
        level = float(u.get("level_numeric") or 2.0)

        invite_bias = 0.95 + min(0.6, habit / 9.0) + random.uniform(-0.10, 0.10)
        # level cao có thể "kén" hơn nhẹ, nhưng không quá cực đoan
        accept_bias = 1.10 - min(0.28, (level - 2.0) * 0.05) + random.uniform(-0.12, 0.12)

        quota = int(_clamp(round(1 + habit / 2.8 + random.uniform(-0.6, 0.8)), 1, invite_cap))

        prop[uid] = {
            "invite_bias": _clamp(invite_bias, 0.6, 1.6),
            "accept_bias": _clamp(accept_bias, 0.6, 1.6),
            "quota": float(quota),
        }
    return prop


def _p_click(rule_score: float, rank: int, synergy: float) -> float:
    """
    Click profile: phụ thuộc exposure(rank) + chất lượng match.
    """
    exposure = _exposure_probability(rank)
    s = _clamp(rule_score / 100.0, 0.0, 1.0)
    logit = -1.75 + 1.55 * exposure + 1.05 * s + 0.85 * synergy
    p = _sigmoid(logit)
    return _clamp(p, 0.02, 0.72)


def _p_dismiss(rule_score: float, rank: int, synergy: float) -> float:
    """
    Dismiss: xảy ra khi match quality thấp.
    """
    exposure = _exposure_probability(rank)
    s = _clamp(rule_score / 100.0, 0.0, 1.0)
    badness = 1.0 - (0.62 * s + 0.38 * synergy)
    logit = -2.35 + 1.85 * badness + 0.25 * exposure
    return _clamp(_sigmoid(logit), 0.01, 0.22)


def _p_invite(
    rule_score: float,
    rank: int,
    synergy: float,
    invite_bias: float,
    *,
    invite_boost: float,
) -> float:
    """
    Invite: phụ thuộc exposure + score + synergy + cá tính user.
    invite_boost (>1.0) giúp tăng số invite để giảm lệch nhãn ở tầng accept.
    """
    exposure = _exposure_probability(rank)
    s = _clamp(rule_score / 100.0, 0.0, 1.0)
    logit = -2.10 + 2.25 * s + 1.10 * synergy + 0.85 * exposure + math.log(invite_bias)
    p = exposure * _sigmoid(logit) * invite_boost
    return _clamp(p, 0.002, 0.50)


def _p_accept(
    rule_score: float,
    synergy: float,
    accept_bias_receiver: float,
    *,
    accept_boost: float,
) -> float:
    """
    Accept|Invited: quyết định của người nhận.
    accept_boost (>1.0) tăng tỉ lệ accepted (hợp lý) khi seed dữ liệu.
    """
    s = _clamp(rule_score / 100.0, 0.0, 1.0)
    logit = -1.90 + 2.05 * s + 1.10 * synergy + math.log(accept_bias_receiver)
    p = _sigmoid(logit) * accept_boost
    return _clamp(p, 0.01, 0.75)


def _sample_feedback(rule_score: float, synergy: float) -> str:
    score_norm = _clamp(rule_score / 100.0, 0.0, 1.0)
    happiness = 0.5 * score_norm + 0.5 * synergy
    r = random.random()

    if happiness > 0.75:
        return "good" if r < 0.8 else "ok"
    if happiness > 0.4:
        if r < 0.15:
            return "good"
        if r < 0.75:
            return "ok"
        return "bad"
    return "ok" if r < 0.2 else "bad"


# ---------------------------------------------------------------------
# POCKETBASE FETCH
# ---------------------------------------------------------------------

async def fetch_all_user_details() -> List[Dict[str, Any]]:
    await ensure_user_login()

    all_items: List[Dict[str, Any]] = []
    page = 1
    per_page = 200

    while True:
        data = await get_list("user_details", page=page, per_page=per_page, filter_expr=None)
        items = data.get("items", [])
        if not items:
            break
        all_items.extend(items)
        if len(items) < per_page:
            break
        page += 1

    print(f"[INFO] fetched {len(all_items)} user_details")
    return all_items


async def fetch_latest_logs_for_user(from_user_id: str, limit: int = 20) -> List[Dict[str, Any]]:
    """
    Lấy log mới nhất cho 1 user sau khi gọi recommend.
    Ghi chú: Nếu wrapper get_list của bạn hỗ trợ sort, nên sort=-created để chắc chắn lấy session mới nhất.
    """
    await ensure_user_login()
    filter_expr = f'from_user="{from_user_id}"'
    data = await get_list("recommendation_logs", page=1, per_page=limit, filter_expr=filter_expr)
    items = data.get("items", [])
    return items


# ---------------------------------------------------------------------
# FASTAPI CALLS
# ---------------------------------------------------------------------

async def call_recommend_for_user(session: aiohttp.ClientSession, user_id: str, limit: int) -> None:
    mode = random.choice(["players", "friends"])
    endpoint = "/recommend/players" if mode == "players" else "/recommend/friends"
    url = f"{FASTAPI_BASE_URL}{endpoint}?user_id={user_id}&limit={limit}"

    async with session.get(url) as res:
        if res.status != 200:
            text = await res.text()
            print(f"[WARN] recommend {mode} failed for {user_id}: {res.status} {text}")
        else:
            print(f"[OK] recommend {mode} called for user {user_id}")


# ---------------------------------------------------------------------
# CORE: SESSION-BASED FUNNEL SIMULATION
# ---------------------------------------------------------------------

async def simulate_one_session(
    *,
    from_user_id: str,
    user_prop: Dict[str, Dict[str, float]],
    feedback_ratio: float,
    logs_limit: int,
    min_invites: int,
    ignore_rate: float,
    invite_boost: float,
    accept_boost: float,
    synthetic_version: str,
) -> Tuple[int, int, int, int]:
    """
    Trả về thống kê: (shown_count, click_count, invite_count, accept_count)

    min_invites:
      - đảm bảo mỗi session có tối thiểu X invite (nếu có đủ ứng viên đã click + không dismiss),
        giúp tạo dữ liệu invited để train accept-model.
    """
    session_id = str(uuid.uuid4())
    shown_at = _now_iso()

    logs = await fetch_latest_logs_for_user(from_user_id, limit=logs_limit)
    if not logs:
        return (0, 0, 0, 0)

    logs.sort(key=lambda x: float(x.get("rank_in_list") or 9999))

    inviter = user_prop.get(from_user_id, {"invite_bias": 1.0, "accept_bias": 1.0, "quota": 2.0})
    invite_quota = int(inviter["quota"])
    invites_sent = 0

    shown_count = click_count = invite_count = accept_count = 0

    # track candidate ids that are eligible to "force invite" to satisfy min_invites
    eligible_after_click: List[Tuple[Dict[str, Any], Dict[str, Any], float, int, float]] = []

    for idx, log in enumerate(logs, start=1):
        features = log.get("features") or {}
        if not isinstance(features, dict):
            features = {}

        # chỉ seed log chưa thuộc version này (tránh ghi đè)
        if features.get("synthetic_version") == synthetic_version:
            continue

        to_user = log.get("to_user")
        if not isinstance(to_user, str) or not to_user:
            continue

        rule_score = float(log.get("rule_score") or 0.0)
        rank_shown = idx
        synergy = _extract_synergy(features)
        exposure_p = _exposure_probability(rank_shown)

        # --- 1) SHOWN ---
        shown_count += 1
        features["synthetic_version"] = synthetic_version
        features["session_id"] = session_id
        features["shown_at"] = shown_at
        features["rank_shown"] = rank_shown
        features["exposure_p"] = round(exposure_p, 3)

        await update_record(
            "recommendation_logs",
            log["id"],
            {
                "shown": True,
                "shown_at": shown_at,
                "session_id": session_id,
                "rank_shown": rank_shown,
                "features": features,
            },
        )

        # --- 2) CLICK PROFILE ---
        pclick = _p_click(rule_score, rank_shown, synergy)
        clicked = random.random() < pclick
        features["sim_p_click"] = round(pclick, 3)

        if clicked:
            click_count += 1
            features["clicked_profile"] = True
            await update_record(
                "recommendation_logs",
                log["id"],
                {"clicked_profile": True, "features": features},
            )
        else:
            continue  # không click => ignore

        # --- 3) DISMISS or INVITE (chỉ khi đã click) ---
        pdismiss = _p_dismiss(rule_score, rank_shown, synergy)
        dismissed = random.random() < pdismiss
        features["sim_p_dismiss"] = round(pdismiss, 3)

        if dismissed:
            features["dismiss_reason"] = random.choice(
                ["not_matching_style", "too_far", "not_active", "other"]
            )
            await update_record(
                "recommendation_logs",
                log["id"],
                {"rejected": True, "responded": True, "features": features},
            )
            continue

        # candidate eligible for invite (store to maybe force invite later)
        eligible_after_click.append((log, features, rule_score, rank_shown, synergy))

        # if quota exhausted, keep scanning for eligibility but don't invite now
        if invites_sent >= invite_quota:
            features["response"] = "ignored_quota"
            await update_record("recommendation_logs", log["id"], {"features": features})
            continue

        pinv = _p_invite(rule_score, rank_shown, synergy, inviter["invite_bias"], invite_boost=invite_boost)
        invited = random.random() < pinv
        features["sim_p_invited"] = round(pinv, 3)

        if not invited:
            features["response"] = "no_invite"
            await update_record("recommendation_logs", log["id"], {"features": features})
            continue

        # invited
        invites_sent += 1
        invite_count += 1
        features["invited_at"] = _now_iso()

        await update_record(
            "recommendation_logs",
            log["id"],
            {"invited": True, "responded": True, "features": features},
        )

        # --- 4) OUTCOME: ACCEPT / REJECT / IGNORE ---
        receiver = user_prop.get(to_user, {"accept_bias": 1.0})
        pacc = _p_accept(rule_score, synergy, receiver["accept_bias"], accept_boost=accept_boost)
        features["sim_p_accepted"] = round(pacc, 3)

        # ignore rate configurable
        if random.random() < ignore_rate:
            features["response"] = "ignored"
            await update_record("recommendation_logs", log["id"], {"features": features})
            continue

        accepted = (random.random() < pacc)
        if accepted:
            accept_count += 1
            features["response"] = "accepted"
            await update_record("recommendation_logs", log["id"], {"accepted": True, "features": features})

            if random.random() < feedback_ratio:
                fb = _sample_feedback(rule_score, synergy)
                try:
                    await create_match_feedback(
                        from_user_id=from_user_id,
                        to_user_id=to_user,
                        booking_id=None,
                        feedback=fb,
                        comment=fb,
                    )
                except Exception as e:
                    print(f"[WARN] cannot create match_feedback for log {log.get('id')}: {e}")
        else:
            features["response"] = "rejected"
            await update_record("recommendation_logs", log["id"], {"rejected": True, "features": features})

    # -----------------------------------------------------------------
    # Force invites to satisfy min_invites (optional)
    # -----------------------------------------------------------------
    if min_invites > 0 and invite_count < min_invites and eligible_after_click:
        # rank candidates: prefer higher rule_score + synergy + high exposure
        def _cand_score(tup: Tuple[Dict[str, Any], Dict[str, Any], float, int, float]) -> float:
            _log, _feat, _rs, _rank, _syn = tup
            return (0.65 * (_rs / 100.0) + 0.35 * _syn) * _exposure_probability(_rank)

        eligible_after_click.sort(key=_cand_score, reverse=True)

        for (log, features, rule_score, rank_shown, synergy) in eligible_after_click:
            if invite_count >= min_invites:
                break
            if invites_sent >= invite_quota:
                break

            # skip if already invited by earlier path
            if bool(log.get("invited")):
                continue

            # mark invited
            invites_sent += 1
            invite_count += 1
            features["forced_invite"] = True
            features["invited_at"] = _now_iso()

            await update_record(
                "recommendation_logs",
                log["id"],
                {"invited": True, "responded": True, "features": features},
            )

            # outcome
            to_user = log.get("to_user")
            receiver = user_prop.get(str(to_user), {"accept_bias": 1.0})
            pacc = _p_accept(rule_score, synergy, receiver["accept_bias"], accept_boost=accept_boost)
            features["sim_p_accepted"] = round(pacc, 3)

            if random.random() < ignore_rate:
                features["response"] = "ignored"
                await update_record("recommendation_logs", log["id"], {"features": features})
                continue

            accepted = (random.random() < pacc)
            if accepted:
                accept_count += 1
                features["response"] = "accepted"
                await update_record("recommendation_logs", log["id"], {"accepted": True, "features": features})

                if random.random() < feedback_ratio:
                    fb = _sample_feedback(rule_score, synergy)
                    try:
                        await create_match_feedback(
                            from_user_id=from_user_id,
                            to_user_id=str(to_user),
                            booking_id=None,
                            feedback=fb,
                            comment=fb,
                        )
                    except Exception as e:
                        print(f"[WARN] cannot create match_feedback for log {log.get('id')}: {e}")
            else:
                features["response"] = "rejected"
                await update_record("recommendation_logs", log["id"], {"rejected": True, "features": features})

    return (shown_count, click_count, invite_count, accept_count)


async def run_simulation(
    *,
    rounds: int,
    feedback_ratio: float,
    seed: int,
    rec_limit: int,
    logs_limit: int,
    min_invites: int,
    invite_cap: int,
    ignore_rate: float,
    invite_boost: float,
    accept_boost: float,
    synthetic_version: str,
) -> None:
    random.seed(seed)

    users = await fetch_all_user_details()
    user_ids: List[str] = [
        str(u["user_id"]) for u in users if isinstance(u.get("user_id"), str) and u["user_id"]
    ]
    if len(user_ids) < 2:
        print("[ERROR] not enough users in user_details (need >= 2).")
        return

    user_prop = _build_user_propensity(users, invite_cap=invite_cap)

    shown_total = click_total = invite_total = accept_total = 0

    async with aiohttp.ClientSession() as session:
        for i in range(rounds):
            uid = random.choice(user_ids)

            # 1) call recommend to create fresh logs
            try:
                await call_recommend_for_user(session, uid, limit=rec_limit)
            except Exception as e:
                print("[WARN] recommend call failed:", e)
                continue

            # 2) simulate session behavior on latest logs
            try:
                s, c, inv, acc = await simulate_one_session(
                    from_user_id=uid,
                    user_prop=user_prop,
                    feedback_ratio=feedback_ratio,
                    logs_limit=logs_limit,
                    min_invites=min_invites,
                    ignore_rate=ignore_rate,
                    invite_boost=invite_boost,
                    accept_boost=accept_boost,
                    synthetic_version=synthetic_version,
                )
                shown_total += s
                click_total += c
                invite_total += inv
                accept_total += acc
            except Exception as e:
                print("[WARN] simulate session failed:", e)

            if (i + 1) % 10 == 0:
                print(
                    f"[PROGRESS] rounds={i+1}/{rounds} "
                    f"shown={shown_total}, click={click_total}, invite={invite_total}, accept={accept_total}"
                )

    print(
        f"[DONE] rounds={rounds} "
        f"shown={shown_total}, click={click_total}, invite={invite_total}, accept={accept_total} "
        f"(seed={seed}, version={synthetic_version})"
    )


# ---------------------------------------------------------------------
# ENTRYPOINT
# ---------------------------------------------------------------------

def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Generate advanced synthetic interactions (session funnel) - V4.")
    p.add_argument("--rounds", type=int, default=200, help="Số session mô phỏng (mỗi session gọi recommend 1 user).")
    p.add_argument("--feedback-ratio", type=float, default=0.4, help="Tỉ lệ accepted sinh match_feedback (0..1).")
    p.add_argument("--seed", type=int, default=42, help="Seed để tái lập dữ liệu (random).")

    p.add_argument("--rec-limit", type=int, default=30, help="Số gợi ý FastAPI tạo ra mỗi lần gọi recommend.")
    p.add_argument("--logs-limit", type=int, default=30, help="Số log lấy về để mô phỏng 1 session (rank 1..N).")

    p.add_argument("--min-invites", type=int, default=1, help="Ép tối thiểu X invite / session (nếu đủ ứng viên).")
    p.add_argument("--invite-cap", type=int, default=5, help="Trần quota invite / session (1..invite-cap).")
    p.add_argument("--ignore-rate", type=float, default=0.10, help="Tỉ lệ người nhận IGNORE lời mời (0..1).")

    p.add_argument("--invite-boost", type=float, default=1.25, help="Hệ số boost xác suất invite (>1 tăng invite).")
    p.add_argument("--accept-boost", type=float, default=1.10, help="Hệ số boost xác suất accept (>1 tăng accepted).")

    p.add_argument(
        "--synthetic-version",
        type=str,
        default="v4_funnel_seed",
        help="Tag version để tránh seed đè lên log đã seed cùng version.",
    )
    return p.parse_args()


async def main() -> None:
    args = parse_args()
    await run_simulation(
        rounds=args.rounds,
        feedback_ratio=args.feedback_ratio,
        seed=args.seed,
        rec_limit=args.rec_limit,
        logs_limit=args.logs_limit,
        min_invites=args.min_invites,
        invite_cap=args.invite_cap,
        ignore_rate=args.ignore_rate,
        invite_boost=args.invite_boost,
        accept_boost=args.accept_boost,
        synthetic_version=args.synthetic_version,
    )


if __name__ == "__main__":
    asyncio.run(main())
