import json
from datetime import datetime
from pathlib import Path
from typing import Tuple, List, Optional, Dict

import joblib
import numpy as np
import pandas as pd
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import (
    classification_report,
    confusion_matrix,
    roc_auc_score,
    average_precision_score,
    roc_curve,
    precision_recall_curve,
)
from sklearn.model_selection import StratifiedKFold, train_test_split, cross_val_score
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler
import matplotlib.pyplot as plt

# =========================
# CONFIG
# =========================
BASE_DIR = Path(__file__).resolve().parent
DATA_DIR = BASE_DIR / "data"
ARTIFACTS_DIR = BASE_DIR / "artifacts"
EXPERIMENTS_DIR = BASE_DIR / "experiments"

DATA_PATH = DATA_DIR / "training_dataset.csv"
SEED = 42

# Nếu True: bỏ sim_p_* (khuyến nghị cho "ML đích thực")
CLEAN_MODE = True

# Top-K metrics (phù hợp recommender)
TOPK_LIST = [5, 10, 20]


# =========================
# IO
# =========================
def load_data(path: Path | str) -> Tuple[pd.DataFrame, str]:
    """
    Load dataset và trả về (df, label_column_name).
    low_memory=False để giảm DtypeWarning.
    """
    df = pd.read_csv(Path(path), low_memory=False)

    if "label_accepted" in df.columns:
        y_col = "label_accepted"
    elif "accepted" in df.columns:
        y_col = "accepted"
    else:
        raise ValueError("Dataset không có cột label_accepted hoặc accepted.")

    return df, y_col


# =========================
# FEATURE RESOLUTION
# =========================
def resolve_feature_cols(df: pd.DataFrame, clean_mode: bool) -> List[str]:
    """
    Tự detect schema:
    - Version mới: prefix f_
    - Version cũ: không prefix

    clean_mode=True sẽ bỏ các cột sim_p_* để tránh leakage từ synthetic generator.
    """
    # v2 (prefix f_)
    base_v2 = [
        "rule_score",
        "rank_in_list",
        "f_level",
        "f_style",
        "f_role",
        "f_intensity",
        "f_home_court",
        "f_habit",
        "f_court",
        "is_top3",
    ]
    sim_v2 = ["f_sim_p_accepted", "f_sim_p_invited"]

    # v1 (no prefix)
    base_v1 = [
        "rule_score",
        "rank_in_list",
        "level",
        "style",
        "role",
        "intensity",
        "home_court",
        "habit",
        "court",
        "is_top3",
    ]
    sim_v1 = ["sim_p_accepted", "sim_p_invited"]

    # detect v2
    if all(c in df.columns for c in base_v2):
        cols = base_v2.copy()
        if (not clean_mode) and all(c in df.columns for c in sim_v2):
            cols += sim_v2
        return cols

    # detect v1
    if all(c in df.columns for c in base_v1):
        cols = base_v1.copy()
        if (not clean_mode) and all(c in df.columns for c in sim_v1):
            cols += sim_v1
        return cols

    raise ValueError(
        "Không detect được schema feature.\n"
        "Hãy kiểm tra training_dataset.csv có các cột f_* hoặc cột không prefix."
    )


# =========================
# CLEAN FEATURES
# =========================
def clean_features(df: pd.DataFrame, feature_cols: List[str]) -> pd.DataFrame:
    """
    - cast numeric an toàn (string -> NaN)
    - fill NaN theo median (fallback 0)
    """
    X = df[feature_cols].copy()

    # bool -> int
    for col in X.columns:
        if X[col].dtype == bool:
            X[col] = X[col].astype(int)

    # cast numeric
    for col in X.columns:
        X[col] = pd.to_numeric(X[col], errors="coerce")

    # fill NaN
    for col in X.columns:
        med = X[col].median()
        if np.isnan(med):
            med = 0.0
        X[col] = X[col].fillna(med)

    return X


# =========================
# TOP-K METRICS
# =========================
def topk_metrics(y_true: np.ndarray, y_score: np.ndarray, ks: List[int]) -> Dict[str, float]:
    """
    Precision@K, Recall@K cho tập test theo score.
    Đây là metric phù hợp hệ gợi ý.
    """
    order = np.argsort(-y_score)  # desc
    y_sorted = y_true[order]

    total_pos = int(y_true.sum())
    metrics: Dict[str, float] = {}

    for k in ks:
        k = min(k, len(y_true))
        topk = y_sorted[:k]
        tp_k = int(topk.sum())

        prec_k = tp_k / k if k > 0 else 0.0
        rec_k = tp_k / total_pos if total_pos > 0 else 0.0

        metrics[f"precision@{k}"] = float(prec_k)
        metrics[f"recall@{k}"] = float(rec_k)

    return metrics


# =========================
# LOG
# =========================
def log_metrics(metrics: dict) -> Path:
    EXPERIMENTS_DIR.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
    path = EXPERIMENTS_DIR / f"accept_predictor_{timestamp}.json"
    with path.open("w", encoding="utf-8") as f:
        json.dump(metrics, f, ensure_ascii=False, indent=2)
    print(f"✅ Metrics saved: {path}")
    return path


# =========================
# PLOTS
# =========================
def plot_roc_pr_curves(y_true: np.ndarray, y_score: np.ndarray) -> Path:
    EXPERIMENTS_DIR.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
    path = EXPERIMENTS_DIR / f"accept_predictor_curves_{timestamp}.png"

    fpr, tpr, _ = roc_curve(y_true, y_score)
    precision, recall, _ = precision_recall_curve(y_true, y_score)

    fig, axes = plt.subplots(1, 2, figsize=(10, 4))

    axes[0].plot(fpr, tpr, color="tab:blue", label="ROC")
    axes[0].plot([0, 1], [0, 1], linestyle="--", color="gray", label="Random")
    axes[0].set_xlabel("False Positive Rate")
    axes[0].set_ylabel("True Positive Rate")
    axes[0].set_title("ROC Curve")
    axes[0].legend(loc="lower right")

    axes[1].plot(recall, precision, color="tab:green", label="PR")
    axes[1].set_xlabel("Recall")
    axes[1].set_ylabel("Precision")
    axes[1].set_title("Precision-Recall Curve")
    axes[1].legend(loc="lower left")

    fig.tight_layout()
    fig.savefig(path, dpi=150)
    plt.close(fig)
    print(f"✅ Curves saved: {path}")
    return path


# =========================
# TRAIN
# =========================
def train() -> None:
    df, y_col = load_data(DATA_PATH)
    feature_cols = resolve_feature_cols(df, clean_mode=CLEAN_MODE)

    X = clean_features(df, feature_cols)
    y = pd.to_numeric(df[y_col], errors="coerce").fillna(0).astype(int)

    print("📌 Label:", y_col)
    print("📌 CLEAN_MODE:", CLEAN_MODE)
    print("📌 Features:", feature_cols)
    print("📊 Class distribution:")
    print(y.value_counts())

    if y.nunique() < 2:
        raise ValueError("Dataset chỉ có 1 lớp (toàn 0 hoặc toàn 1). Không thể train model.")

    # split
    X_train, X_test, y_train, y_test = train_test_split(
        X,
        y,
        test_size=0.2,
        random_state=SEED,
        stratify=y,
    )

    # model
    pipeline = Pipeline(
        steps=[
            ("scaler", StandardScaler()),
            (
                "model",
                LogisticRegression(
                    max_iter=2000,
                    class_weight="balanced",
                    random_state=SEED,
                ),
            ),
        ]
    )

    pipeline.fit(X_train, y_train)

    # predict proba
    y_proba = pipeline.predict_proba(X_test)[:, 1]

    # threshold 0.5 chỉ để xem classification report (không phải metric chính cho recommender)
    y_pred = (y_proba >= 0.5).astype(int)

    roc_auc = roc_auc_score(y_test, y_proba)
    pr_auc = average_precision_score(y_test, y_proba)
    report = classification_report(y_test, y_pred, output_dict=True, zero_division=0)
    cm = confusion_matrix(y_test, y_pred).tolist()

    # Top-K metrics
    y_test_np = y_test.to_numpy()
    topk = topk_metrics(y_test_np, y_proba, TOPK_LIST)

    print("✅ ROC-AUC:", roc_auc)
    print("✅ PR-AUC:", pr_auc)
    print("✅ Confusion matrix:", cm)
    print("✅ Top-K:", topk)
    print(classification_report(y_test, y_pred, zero_division=0))

    plot_roc_pr_curves(y_test_np, y_proba)

    # CV (ROC-AUC)
    min_class = int(y.value_counts().min())
    cv_scores: Optional[np.ndarray]
    if min_class < 2:
        cv_scores = None
        print(f"⚠️  Skip CV (min_class={min_class})")
    else:
        n_splits = min(5, min_class)
        skf = StratifiedKFold(n_splits=n_splits, shuffle=True, random_state=SEED)
        cv_scores = cross_val_score(pipeline, X, y, cv=skf, scoring="roc_auc")

    # Save artifacts
    ARTIFACTS_DIR.mkdir(parents=True, exist_ok=True)
    pipeline_path = ARTIFACTS_DIR / "pipeline_predictor.pkl"
    joblib.dump(pipeline, pipeline_path)
    print("✅ Saved pipeline:", pipeline_path)

    metrics = {
        "seed": SEED,
        "clean_mode": CLEAN_MODE,
        "data_path": str(DATA_PATH),
        "label_col": y_col,
        "feature_order": feature_cols,
        "class_distribution": y.value_counts().to_dict(),
        "threshold": 0.5,
        "roc_auc": float(roc_auc),
        "pr_auc": float(pr_auc),
        "confusion_matrix": cm,
        "topk_metrics": topk,
        "cv_roc_auc_mean": None if cv_scores is None else float(cv_scores.mean()),
        "cv_roc_auc_std": None if cv_scores is None else float(cv_scores.std()),
        "classification_report": report,
    }
    log_metrics(metrics)


if __name__ == "__main__":
    train()
