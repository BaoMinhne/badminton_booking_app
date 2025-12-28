"""app/services/logistic_regression.py

Nhiệm vụ:
- Load model ML đã train (ưu tiên pipeline_predictor.pkl).
- Chuẩn hoá feature schema theo đúng thứ tự lúc train (CLEAN_MODE=True).
- Trả về xác suất accept (0..1) để dùng re-rank.

Ghi chú triển khai:
- Hỗ trợ 3 kiểu artifact:
  (1) pipeline_predictor.pkl  (khuyến nghị, bạn đang dùng)
  (2) pipeline_accept_predictor.pkl
  (3) model_accept_predictor.pkl + scaler_accept_predictor.pkl (legacy)
- Hỗ trợ 2 schema feature:
  - v2: prefix f_ (đúng với training_dataset.csv của bạn)
  - v1: không prefix
"""

from __future__ import annotations

import logging
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

import joblib
import numpy as np
import pandas as pd

logger = logging.getLogger("recommender.ml")

BASE_DIR = Path(__file__).resolve().parents[2]  # project root (chứa app/)
ARTIFACTS_DIR = BASE_DIR / "artifacts"

# New (pipeline) artifacts
PIPELINE_PATHS = [
    ARTIFACTS_DIR / "pipeline_predictor.pkl",
    ARTIFACTS_DIR / "pipeline_accept_predictor.pkl",
]

# Legacy artifacts
MODEL_PATH = ARTIFACTS_DIR / "model_accept_predictor.pkl"
SCALER_PATH = ARTIFACTS_DIR / "scaler_accept_predictor.pkl"


# CLEAN_MODE feature order (khuyến nghị)
FEATURE_ORDER_CLEAN_V2: List[str] = [
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

FEATURE_ORDER_CLEAN_V1: List[str] = [
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

# Legacy (có sim_p_*)
FEATURE_ORDER_LEGACY_V2: List[str] = FEATURE_ORDER_CLEAN_V2[:-1] + [
    "f_sim_p_accepted",
    "f_sim_p_invited",
    "is_top3",
]
FEATURE_ORDER_LEGACY_V1: List[str] = FEATURE_ORDER_CLEAN_V1[:-1] + [
    "sim_p_accepted",
    "sim_p_invited",
    "is_top3",
]


_pipeline: Optional[Any] = None
_legacy_model: Optional[Any] = None
_legacy_scaler: Optional[Any] = None


def _safe_load(path: Path, kind: str) -> Optional[Any]:
    if not path.exists():
        return None
    try:
        obj = joblib.load(path)
        logger.info("[ml_artifact_loaded] kind=%s path=%s", kind, path)
        return obj
    except Exception:
        logger.exception("[ml_artifact_load_error] kind=%s path=%s", kind, path)
        return None


def _load_artifacts() -> None:
    global _pipeline, _legacy_model, _legacy_scaler

    if _pipeline is None:
        for p in PIPELINE_PATHS:
            _pipeline = _safe_load(p, "pipeline")
            if _pipeline is not None:
                break

    # fallback legacy
    if _pipeline is None:
        if _legacy_model is None:
            _legacy_model = _safe_load(MODEL_PATH, "model")
        if _legacy_scaler is None:
            _legacy_scaler = _safe_load(SCALER_PATH, "scaler")


def _pick_feature_order(features: Dict[str, Any]) -> List[str]:
    """Ưu tiên schema CLEAN v2 (f_*), rồi CLEAN v1, rồi legacy."""
    keys = set(features.keys())

    if all(k in keys for k in FEATURE_ORDER_CLEAN_V2):
        return FEATURE_ORDER_CLEAN_V2
    if all(k in keys for k in FEATURE_ORDER_CLEAN_V1):
        return FEATURE_ORDER_CLEAN_V1

    # legacy
    if all(k in keys for k in FEATURE_ORDER_LEGACY_V2):
        return FEATURE_ORDER_LEGACY_V2
    if all(k in keys for k in FEATURE_ORDER_LEGACY_V1):
        return FEATURE_ORDER_LEGACY_V1

    # nếu thiếu, vẫn cố gắng theo CLEAN_V2 (vì runtime có thể không có đủ)
    # -> sẽ fill 0 cho missing
    if any(k.startswith("f_") for k in keys):
        return FEATURE_ORDER_CLEAN_V2
    return FEATURE_ORDER_CLEAN_V1


def _to_float(x: Any) -> float:
    try:
        if x is None:
            return 0.0
        if isinstance(x, bool):
            return float(int(x))
        return float(x)
    except Exception:
        return 0.0


def _sanitize(features: Dict[str, Any]) -> Tuple[pd.DataFrame, Dict[str, List[str]]]:
    order = _pick_feature_order(features)
    missing = [c for c in order if c not in features]
    unexpected = [c for c in features.keys() if c not in order]

    row = {c: _to_float(features.get(c, 0.0)) for c in order}
    x_df = pd.DataFrame([row], columns=order)

    # đảm bảo numeric
    for c in order:
        x_df[c] = pd.to_numeric(x_df[c], errors="coerce").fillna(0.0)

    return x_df, {"missing": missing, "unexpected": unexpected, "order": order}


def predict_accept_probability(features: Dict[str, Any]) -> Optional[float]:
    """Trả về P(accepted=1). None nếu artifact không sẵn sàng."""
    _load_artifacts()

    x_df, info = _sanitize(features)
    if info["missing"]:
        logger.debug("[ml_feature_missing] missing=%s", info["missing"])

    try:
        if _pipeline is not None:
            proba = _pipeline.predict_proba(x_df)[0][1]
            return float(proba)

        if _legacy_model is None or _legacy_scaler is None:
            logger.warning("[ml_fallback_rule_only] reason=artifact_unavailable")
            return None

        x_scaled = _legacy_scaler.transform(x_df)
        proba = _legacy_model.predict_proba(x_scaled)[0][1]
        return float(proba)
    except Exception:
        logger.exception("[ml_predict_error]")
        return None
