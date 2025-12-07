# app/services/ml_model.py
from pathlib import Path
from typing import Dict, List, Optional
import joblib
import numpy as np
import pandas as pd

BASE_DIR = Path(__file__).resolve().parents[2]

MODEL_PATH = BASE_DIR / "model_accept_predictor.pkl"
SCALER_PATH = BASE_DIR / "scaler_accept_predictor.pkl"

FEATURE_ORDER: List[str] = [
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

from sklearn.linear_model import LogisticRegression
from sklearn.preprocessing import StandardScaler

_model: Optional[LogisticRegression] = None
_scaler: Optional[StandardScaler] = None


def _load_artifacts() -> None:
    global _model, _scaler

    if _model is None:
        _model = joblib.load(MODEL_PATH)

    if _scaler is None:
        _scaler = joblib.load(SCALER_PATH)


def predict_accept_probability(features: Dict[str, float]) -> Optional[float]:
    try:
        _load_artifacts()

        if _model is None or _scaler is None:
            return None  # fallback safe

        # Build DataFrame đúng thứ tự features
        x_df = pd.DataFrame(
            [features], 
            columns=FEATURE_ORDER
        )

        # Transform
        x_scaled = _scaler.transform(x_df)

        # Predict probability class=1 (accepted)
        prob = _model.predict_proba(x_scaled)[0][1]
        return float(prob)

    except Exception as e:
        print("[ML_MODEL][WARN] ML model error:", e)
        return None
