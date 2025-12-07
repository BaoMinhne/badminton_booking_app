import pandas as pd
import ast
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
DATA_DIR = BASE_DIR / "data"
INPUT_CSV = DATA_DIR / "recommendation_logs.csv"
OUTPUT_CSV = DATA_DIR / "training_dataset.csv"

def main():
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    df = pd.read_csv(INPUT_CSV)

    # 1. Parse cột features (JSON string) thành dict
    def parse_features(x):
        if pd.isna(x):
            return {}
        try:
            return ast.literal_eval(x)
        except Exception:
            return {}

    df["features_dict"] = df["features"].apply(parse_features)

    # 2. Tách các key trong features_dict thành cột riêng
    feat_df = df["features_dict"].apply(pd.Series)

    # Ví dụ: đảm bảo các cột quan trọng tồn tại
    for col in ["level", "style", "intensity", "home_court", "habit", "mode"]:
        if col not in feat_df.columns:
            feat_df[col] = None

    # 3. Gộp lại: bỏ cột features cũ, giữ rule_score, rank_in_list, invited, accepted,...
    df_clean = pd.concat(
        [
            df.drop(columns=["features", "features_dict"]),
            feat_df,
        ],
        axis=1,
    )

    # 4. (Tuỳ chọn) Tạo thêm các feature hữu ích
    # Ví dụ: is_top3
    df_clean["is_top3"] = df_clean["rank_in_list"].fillna(999).astype(int) <= 3

    # 5. Chuẩn hóa nhãn accepted thành 0/1
    df_clean["label_accepted"] = df_clean["accepted"].astype(int)

    # 6. Lưu ra file mới để train
    df_clean.to_csv(OUTPUT_CSV, index=False, encoding="utf-8")
    print("Saved:", OUTPUT_CSV, "shape:", df_clean.shape)

if __name__ == "__main__":
    main()
