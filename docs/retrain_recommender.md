# Hướng dẫn huấn luyện lại mô hình gợi ý

Tài liệu này tóm tắt các bước thực hành tốt để huấn luyện lại mô hình Logistic Regression hiện có, đồng thời kiểm soát fallback ở runtime.

## Chuẩn bị môi trường
- Python 3.10+ (khớp với môi trường deploy nếu có thể).
- Cài đặt gói:

```bash
cd recommender_system
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Dữ liệu và đặc trưng
- File dữ liệu: `recommender_system/training_dataset.csv`.
- Bắt buộc phải có các cột: `rule_score, rank_in_list, level, style, role, intensity, home_court, habit, court, sim_p_accepted, sim_p_invited, is_top3, accepted`.
- Nếu không dùng các đặc trưng synthetic `sim_p_*`, hãy điền 0 hoặc loại khỏi pipeline và cập nhật `FEATURE_COLS` trong `train_model.py` + `FEATURE_ORDER` trong `app/services/logistic_regression.py` cho khớp.

## Chạy huấn luyện
Từ thư mục gốc repo:

```bash
python recommender_system/train_model.py
```

Script sẽ:
- Làm sạch dữ liệu (ép kiểu bool → int, điền median cho số, fillna(0)).
- Chia train/test với `random_state=42` để tái lập.
- Huấn luyện `StandardScaler` + `LogisticRegression(class_weight="balanced", max_iter=1000)` trong một `Pipeline`.
- Chạy cross-validation StratifiedKFold(5) để ước lượng độ ổn định accuracy.
- Lưu artifact: `model_accept_predictor.pkl`, `scaler_accept_predictor.pkl`, `pipeline_accept_predictor.pkl` và log metric tại `recommender_system/experiments/accept_predictor_<timestamp>.json`.

## Kiểm tra artifact và deploy
- Đảm bảo cả **model** và **scaler** tồn tại; runtime sẽ fallback về rule-only nếu thiếu và log cảnh báo `[ml_fallback_rule_only]`.
- Đối chiếu thứ tự đặc trưng giữa `train_model.py` và `app/services/logistic_regression.py` trước khi deploy để tránh log `[ml_feature_schema_mismatch]`.

## Mẹo nâng cao
- Nếu thêm đặc trưng mới, hãy chuẩn hóa lại schema, chạy lại huấn luyện và commit cả thay đổi code + artifact mới.
- Lưu ý phân phối lớp: nếu dữ liệu lệch nhiều, xem xét bỏ `class_weight="balanced"` nếu thấy bị over-compensate qua metric validation.
- Để track thí nghiệm kỹ hơn, có thể đẩy metric JSON vào MLflow/Weights & Biases hoặc lưu thêm seed, hash dataset trong file metric.
