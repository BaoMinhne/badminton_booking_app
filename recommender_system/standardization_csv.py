import pandas as pd
import json
import ast
from pathlib import Path

# ----------------------
# PATH CONFIG
# ----------------------
BASE_DIR = Path(__file__).resolve().parent
DATA_DIR = BASE_DIR / "data"
INPUT_CSV = DATA_DIR / "recommendation_logs.csv"
OUTPUT_CSV = DATA_DIR / "training_dataset.csv"

FEATURE_PREFIX = "f_"

IMPORTANT_FEATURE_KEYS = [
    "level", "style", "role", "intensity",
    "home_court", "habit", "mode",
    "rank_shown", "exposure_p",
    "sim_p_click", "sim_p_invited", "sim_p_accepted",
    "response", "dismiss_reason",
]

BOOL_COLUMNS = ["shown", "clicked_profile", "responded", "rejected", "invited", "accepted"]


def parse_features(x) -> dict:
    """
    Parse cột features từ PocketBase:
    - ưu tiên JSON (json.loads)
    - fallback literal_eval (trường hợp dữ liệu bị serialize kiểu python)
    """
    if pd.isna(x) or x is None:
        return {}
    s = str(x).strip()
    if not s:
        return {}

    try:
        return json.loads(s)
    except Exception:
        pass

    try:
        return ast.literal_eval(s)
    except Exception:
        return {}


def to_bool01(x) -> int:
    """
    Chuyển mọi dạng bool về 0/1 ổn định:
    True/False, 'true'/'false', 1/0, NaN
    """
    if pd.isna(x):
        return 0
    if isinstance(x, bool):
        return int(x)

    s = str(x).strip().lower()
    return 1 if s in ("1", "true", "t", "yes", "y") else 0


def main():
    DATA_DIR.mkdir(parents=True, exist_ok=True)

    print("[INFO] Loading:", INPUT_CSV)
    df = pd.read_csv(INPUT_CSV)
    print("[INFO] Raw shape:", df.shape)

    # 1) Parse features
    if "features" not in df.columns:
        raise ValueError("CSV không có cột 'features'. Hãy kiểm tra file recommendation_logs.csv")

    df["features_dict"] = df["features"].apply(parse_features)

    # 2) Expand features -> columns, và prefix để tránh trùng tên
    feat_df = df["features_dict"].apply(pd.Series)
    feat_df = feat_df.add_prefix(FEATURE_PREFIX)

    # 3) Ensure các key quan trọng tồn tại (dưới dạng f_key)
    for k in IMPORTANT_FEATURE_KEYS:
        col = FEATURE_PREFIX + k
        if col not in feat_df.columns:
            feat_df[col] = None

    # 4) Merge
    drop_cols = [c for c in ["features", "features_dict"] if c in df.columns]
    df_clean = pd.concat([df.drop(columns=drop_cols), feat_df], axis=1)

    # 5) SAFEGUARD: nếu vẫn còn duplicate columns thì drop bớt (giữ cột đầu)
    dup_cols = df_clean.columns[df_clean.columns.duplicated()].tolist()
    if dup_cols:
        print("[WARN] Duplicate columns detected (will keep first):", dup_cols)
        df_clean = df_clean.loc[:, ~df_clean.columns.duplicated()]

    # 6) Normalize bool columns (top-level)
    for bcol in BOOL_COLUMNS:
        if bcol in df_clean.columns:
            df_clean[bcol] = df_clean[bcol].apply(to_bool01)

    # 7) Derived feature: is_top3 theo rank_in_list
    if "rank_in_list" in df_clean.columns:
        df_clean["is_top3"] = (
            pd.to_numeric(df_clean["rank_in_list"], errors="coerce")
            .fillna(999)
            .astype(int) <= 3
        )
    else:
        df_clean["is_top3"] = 0

    # 8) Labels
    df_clean["label_invited"] = df_clean["invited"] if "invited" in df_clean.columns else 0
    df_clean["label_accepted"] = df_clean["accepted"] if "accepted" in df_clean.columns else 0

    # 9) Save
    df_clean.to_csv(OUTPUT_CSV, index=False, encoding="utf-8")
    print("[DONE] Saved:", OUTPUT_CSV)
    print("[DONE] Clean shape:", df_clean.shape)


if __name__ == "__main__":
    main()
