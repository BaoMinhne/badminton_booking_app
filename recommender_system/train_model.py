import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import classification_report, accuracy_score
import joblib

DATA_PATH = "training_dataset.csv"


def load_data(path: str) -> pd.DataFrame:
    df = pd.read_csv(path)

    expected_cols = [
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
        "accepted",
    ]
    missing = [c for c in expected_cols if c not in df.columns]
    if missing:
        raise ValueError(f"Thiếu cột trong dataset: {missing}")

    return df


def train():
    df = load_data(DATA_PATH)

    feature_cols = [
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

    X = df[feature_cols].copy()

    # 1) Ép kiểu bool -> int (đặc biệt là is_top3)
    for col in X.select_dtypes(include=["bool"]).columns:
        X[col] = X[col].astype(int)

    # 2) Xử lý giá trị thiếu (NaN)
    #    - Với cột số: điền median
    #    - Với cột còn lại (nếu có): điền 0
    numeric_cols = X.select_dtypes(include=["int64", "float64"]).columns
    for col in numeric_cols:
        median_val = X[col].median()
        X[col] = X[col].fillna(median_val)

    # Phòng hờ vẫn còn NaN ở chỗ nào đó -> fillna(0)
    X = X.fillna(0)

    # 3) Nhãn: accepted (True/False) -> 1/0
    y = df["accepted"].astype(int)

    print("📊 Class distribution (accepted=1 vs 0):")
    print(y.value_counts())

    X_train, X_test, y_train, y_test = train_test_split(
        X,
        y,
        test_size=0.2,
        random_state=42,
        stratify=y,
    )

    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train)
    X_test_scaled = scaler.transform(X_test)

    model = LogisticRegression(max_iter=1000, class_weight="balanced")
    model.fit(X_train_scaled, y_train)

    y_pred = model.predict(X_test_scaled)
    print("✅ Accuracy:", accuracy_score(y_test, y_pred))
    print(classification_report(y_test, y_pred))

    joblib.dump(model, "model_accept_predictor.pkl")
    joblib.dump(scaler, "scaler_accept_predictor.pkl")
    print("✅ Saved model_accept_predictor.pkl & scaler_accept_predictor.pkl")


if __name__ == "__main__":
    train()
