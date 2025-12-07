# app/services/ml_model.py
import logging
from pathlib import Path
from typing import Dict, List, Optional, Tuple

import joblib
import pandas as pd
from sklearn.linear_model import LogisticRegression
from sklearn.preprocessing import StandardScaler

logger = logging.getLogger("recommender.ml")

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

_model: Optional[LogisticRegression] = None
_scaler: Optional[StandardScaler] = None


def _safe_load_artifact(path: Path, kind: str):
    if not path.exists():
        logger.warning("[ml_artifact_missing] kind=%s path=%s", kind, path)
        return None

    try:
        return joblib.load(path)
    except Exception:
        logger.exception("[ml_artifact_load_error] kind=%s path=%s", kind, path)
        return None


def _load_artifacts() -> None:
    global _model, _scaler

    if _model is None:
        _model = _safe_load_artifact(MODEL_PATH, "model")

    if _scaler is None:
        _scaler = _safe_load_artifact(SCALER_PATH, "scaler")


def _sanitize_features(features: Dict[str, float]) -> Tuple[pd.DataFrame, Dict[str, List[str]]]:
    missing = [name for name in FEATURE_ORDER if name not in features]
    unexpected = [name for name in features.keys() if name not in FEATURE_ORDER]

    sanitized = {name: float(features.get(name, 0.0)) for name in FEATURE_ORDER}
    x_df = pd.DataFrame([sanitized], columns=FEATURE_ORDER)

    return x_df, {"missing": missing, "unexpected": unexpected}


def predict_accept_probability(features: Dict[str, float]) -> Optional[float]:
    _load_artifacts()

    if _model is None or _scaler is None:
        logger.warning(
            "[ml_fallback_rule_only] reason=artifact_unavailable model_loaded=%s scaler_loaded=%s",
            _model is not None,
            _scaler is not None,
        )
        return None

    x_df, info = _sanitize_features(features)
    if info["missing"] or info["unexpected"]:
        logger.warning(
            "[ml_feature_schema_mismatch] missing=%s unexpected=%s",
            info["missing"],
            info["unexpected"],
        )

    try:
        x_scaled = _scaler.transform(x_df)
        prob = _model.predict_proba(x_scaled)[0][1]
        return float(prob)
    except Exception:
        logger.exception("[ml_predict_error]")
        return None
