import json
from datetime import datetime
from pathlib import Path

import joblib
import pandas as pd
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import classification_report, accuracy_score
from sklearn.model_selection import StratifiedKFold, cross_val_score, train_test_split
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler

DATA_PATH = "training_dataset.csv"
EXPERIMENTS_DIR = Path("recommender_system/experiments")
SEED = 42

FEATURE_COLS = [
    "rule_score",
    "rank_in_list",
    "level",
    "style",
    "role",
    "intensity",
    "home_court",
    "habit",
    "court",
    "sim_p_accepted",
    "sim_p_invited",
    "is_top3",
]


def load_data(path: str) -> pd.DataFrame:
    df = pd.read_csv(path)

    expected_cols = FEATURE_COLS + ["accepted"]
    missing = [c for c in expected_cols if c not in df.columns]
    if missing:
        raise ValueError(f"Thiếu cột trong dataset: {missing}")

    return df


def _clean_features(df: pd.DataFrame) -> pd.DataFrame:
    X = df[FEATURE_COLS].copy()

    # 1) Ép kiểu bool -> int (đặc biệt là is_top3)
    for col in X.select_dtypes(include=["bool"]).columns:
        X[col] = X[col].astype(int)

    # 2) Xử lý giá trị thiếu (NaN)
    numeric_cols = X.select_dtypes(include=["int64", "float64"]).columns
    for col in numeric_cols:
        median_val = X[col].median()
        X[col] = X[col].fillna(median_val)

    # Phòng hờ vẫn còn NaN ở chỗ nào đó -> fillna(0)
    X = X.fillna(0)
    return X


def _log_metrics(metrics: dict) -> None:
    EXPERIMENTS_DIR.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
    path = EXPERIMENTS_DIR / f"accept_predictor_{timestamp}.json"
    with path.open("w", encoding="utf-8") as f:
        json.dump(metrics, f, ensure_ascii=False, indent=2)
    print(f"✅ Đã lưu metric tại {path}")


def train():
    df = load_data(DATA_PATH)

    X = _clean_features(df)
    y = df["accepted"].astype(int)

    print("📊 Class distribution (accepted=1 vs 0):")
    print(y.value_counts())

    X_train, X_test, y_train, y_test = train_test_split(
        X,
        y,
        test_size=0.2,
        random_state=SEED,
        stratify=y,
    )

    pipeline = Pipeline(
        steps=[
            ("scaler", StandardScaler()),
            (
                "model",
                LogisticRegression(
                    max_iter=1000,
                    class_weight="balanced",
                    random_state=SEED,
                ),
            ),
        ]
    )

    pipeline.fit(X_train, y_train)

    y_pred = pipeline.predict(X_test)
    accuracy = accuracy_score(y_test, y_pred)
    report = classification_report(y_test, y_pred, output_dict=True)

    print("✅ Accuracy:", accuracy)
    print(classification_report(y_test, y_pred))

    # Cross-validation để kiểm soát độ ổn định
    min_class = y.value_counts().min()
    if min_class < 2:
        cv_scores = None
        print("⚠️  Bỏ qua cross-validation vì số mẫu ở một lớp quá ít (", min_class, ")")
    else:
        n_splits = min(5, min_class)
        skf = StratifiedKFold(n_splits=n_splits, shuffle=True, random_state=SEED)
        cv_scores = cross_val_score(pipeline, X, y, cv=skf, scoring="accuracy")

    # Lưu artifact
    # Giữ nguyên model & scaler như runtime đang dùng
    model: LogisticRegression = pipeline.named_steps["model"]
    scaler: StandardScaler = pipeline.named_steps["scaler"]
    joblib.dump(model, "model_accept_predictor.pkl")
    joblib.dump(scaler, "scaler_accept_predictor.pkl")
    joblib.dump(pipeline, "pipeline_accept_predictor.pkl")
    print("✅ Đã lưu model_accept_predictor.pkl, scaler_accept_predictor.pkl và pipeline_accept_predictor.pkl")

    metrics = {
        "seed": SEED,
        "feature_order": FEATURE_COLS,
        "class_distribution": y.value_counts().to_dict(),
        "accuracy": accuracy,
        "cv_accuracy_mean": None if cv_scores is None else float(cv_scores.mean()),
        "cv_accuracy_std": None if cv_scores is None else float(cv_scores.std()),
        "classification_report": report,
    }
    _log_metrics(metrics)


if __name__ == "__main__":
    train()
