# Checklist củng cố mô hình gợi ý

Ghi chú này liệt kê các bước cụ thể để cải thiện bộ gợi ý lai (rule-based + Logistic Regression) và pipeline huấn luyện.

## Độ ổn định khi chạy
- **Fallback khi thiếu artifact**: Nếu không tải được model/scaler, trả về điểm gợi ý chỉ từ rule và ghi log cảnh báo có cấu trúc (chứa user id, hash request, đường dẫn artifact). Tránh để `sim_p_*` bằng 0 im lặng—hoặc tính lại từ tín hiệu sẵn có, hoặc bỏ hẳn và thông báo rõ ràng để downstream biết chúng đang thiếu.
- **Kiểm tra đầu vào**: Cố định thứ tự đặc trưng ở một nơi (schema chung hoặc dataclass) và kiểm tra shape/type trước khi suy luận. Loại bỏ hoặc đặt mặc định cho trường lạ/thiếu; log payload đã được làm sạch để debug.
- **Chuẩn hóa đặc trưng**: Dùng đúng scaler đã huấn luyện cho môi trường production. Nếu thiếu scaler, dùng tạm identity transform nhưng phát cảnh báo và gắn nhãn vào metric để đo tác động.
- **Observability**: Log có cấu trúc gồm phiên bản model, thống kê đặc trưng (min/mean/max) và các thành phần quyết định (điểm rule vs xác suất model). Đếm số lần fallback và số lần các đặc trưng similarity bị bằng 0.

## Chất lượng mô hình
- **Huấn luyện lại với bộ đặc trưng đầy đủ**: Huấn luyện lại Logistic Regression với các đặc trưng `sim_p_*` có giá trị hoặc bỏ hẳn chúng. Kiểm tra cân bằng lớp và chỉ dùng `class_weight` khi cần sau khi quan sát phân phối nhãn.
- **Hiệu chỉnh và phối trộn**: Đánh giá xem tỷ lệ trộn 70/30 còn phù hợp không. Dùng tập calibration để tinh chỉnh trọng số trộn, hoặc hiệu chỉnh xác suất (Platt scaling) trước khi phối với điểm rule.
- **Kỷ luật đánh giá**: Bổ sung cross-validation và hold-out với seed cố định. Theo dõi AUC, precision/recall@k, calibration curve và lưu cùng với model.

## Pipeline huấn luyện tái lập
- **Tính quyết định**: Cố định seed cho việc chia dữ liệu và huấn luyện; lưu seed chung với artifact.
- **Kiểm tra rò rỉ dữ liệu**: Đảm bảo đặc trưng synthetic/derived không dùng thông tin tương lai. Thêm unit test phát hiện rò rỉ (ví dụ dữ liệu tương lai trong đặc trưng similarity).
- **Tiền xử lý thống nhất**: Bọc feature engineering và scaling trong một `Pipeline` và lưu cùng model để runtime dùng đúng các bước.
- **Theo dõi thực nghiệm**: Ghi tham số, metric và artifact vào hệ thống tracking (MLflow, Weights & Biases, hoặc log JSON/YAML nhẹ trong `recommender_system/experiments/`). Bao gồm phiên bản model, hash schema đặc trưng, snapshot/phien bản dataset và trọng số phối trộn.
- **Phiên bản hóa artifact**: Lưu model + scaler theo semantic version hoặc thư mục timestamp; thêm symlink/manifest chỉ định phiên bản production để đơn giản hóa rollback.

## Danh sách hành động nhanh
1) Thêm schema validation + logging có cấu trúc quanh inference; đếm số lần fallback.
2) Đưa tiền xử lý vào `Pipeline` được persist và yêu cầu cả model + scaler cho inference (với fallback rule-only rõ ràng).
3) Huấn luyện lại với đặc trưng similarity (hoặc loại bỏ), đánh giá bằng cross-validation và tinh chỉnh phối trộn sau calibration.
4) Ghi metric và cấu hình vào tracking log, đóng gói artifact có tag version và cập nhật triển khai để load theo version.
