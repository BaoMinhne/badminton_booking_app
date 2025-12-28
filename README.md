# Ứng dụng đặt sân & cộng đồng cầu lông – Courtify

Ứng dụng Flutter giúp người chơi tìm sân, giữ slot theo thời gian thực, thanh toán online và kết nối với cộng đồng cầu lông. Chủ sân có khu vực quản trị riêng để theo dõi lịch, tạo booking offline, cấu hình giá và xem báo cáo. Hệ thống dùng PocketBase cho realtime data, Stripe cho thanh toán và một dịch vụ gợi ý riêng để đề xuất bạn chơi.

## Công nghệ chính
- 🐦 **Flutter 3.6 + Dart 3.6**: phát triển đa nền tảng (Android/iOS/web) với Material 3.
- 🔌 **Provider**: quản lý trạng thái cho auth, user, court, social, manager flows.
- 🗄️ **PocketBase SDK**: đọc/ghi dữ liệu booking, user, social, realtime locking và cache token bằng `SharedPreferences`.
- 💳 **Stripe**: tạo & xác nhận Payment Intent thông qua endpoint backend trung gian (REST).
- 🌐 **Flutter localization**: hỗ trợ tiếng Anh/Việt; định dạng ngày giờ với `intl`.
- ⚙️ **HTTP + dotenv**: cấu hình endpoint qua `.env` và gọi API cho recommender/Stripe.
- 🧠 **Python recommender**: Logistic Regression + rule-based, huấn luyện với scikit-learn và lưu artifact. (thư mục `recommender_system`).

## Chức năng nổi bật
- **Xác thực & onboarding**: đăng nhập, kiểm tra thông tin hồ sơ; ép người dùng hoàn thiện sở thích/chỉ số chơi để nhận gợi ý chính xác.
- **Đặt sân theo thời gian thực**: giữ slot 15 phút, kiểm tra trùng lịch, chuyển trạng thái held → awaiting payment → confirmed/cancelled/expired.
- **Thanh toán online**: tạo Payment Intent cho nhiều booking, xác nhận qua backend và cập nhật trạng thái.
- **Lịch & thanh toán người dùng**: chọn sân/giờ, xem timeline, tổng hợp thời gian & chi phí trước khi xác nhận.
- **Mạng xã hội cầu lông**: feed bài viết, bình luận, like, tuyển đồng đội, chat, yêu cầu kết bạn/invite chơi.
- **Gợi ý bạn chơi/kết bạn**: dịch vụ recommender cung cấp danh sách đề xuất và ghi log tương tác (shown/click/dismiss/action).
- **Khu vực chủ sân (Manager)**: dashboard, lịch đặt sân, tạo booking offline, quản lý sân & dịch vụ, báo cáo doanh thu.
- **Tài liệu thiết kế/khắc phục**: luồng booking, giải thích lỗi lời mời, checklist cải thiện recommender, hướng dẫn retrain (thư mục `docs/`).

## Yêu cầu môi trường
- Flutter SDK 3.6.x (Dart 3.6.x) và Android Studio/Xcode cho thiết bị mục tiêu.
- PocketBase server đang chạy và reachable từ thiết bị/emulator.
- Backend trung gian Stripe để tạo/confirm Payment Intent.
- (Tuỳ chọn) API recommender (mặc định `http://10.0.2.2:8000` cho Android emulator).

## Thiết lập & chạy ứng dụng
```bash
# Cài đặt phụ thuộc
flutter pub get

# Chạy ứng dụng (chọn thiết bị đã kết nối)
flutter run

# Phân tích mã (tĩnh)
flutter analyze
```

## Cấu hình biến môi trường
Tạo file `.env` ở thư mục gốc với các biến sau:
```bash
# PocketBase
POCKETBASE_URL=http://10.0.2.2:8090

# Stripe
STRIPE_PUBLISHABLE_KEY=pk_test_xxx
STRIPE_MERCHANT_IDENTIFIER=com.example.courtify      # tuỳ chọn cho iOS
STRIPE_PAYMENT_INTENT_URL=https://your-backend.example.com/payments/intents
STRIPE_PAYMENT_CONFIRM_URL=https://your-backend.example.com/payments/confirm

# Recommender
RECOMMENDER_BASE_URL=http://10.0.2.2:8000
```
> Ứng dụng sẽ báo lỗi nếu thiếu khoá Stripe publishable hoặc URL PocketBase.

## Cấu trúc thư mục chính
```
lib/
├─ main.dart                 # Entry point, đa ngôn ngữ, định tuyến theo vai trò
├─ components/               # Widget tái sử dụng (post, timeline, dialogs...)
├─ pages/                    # Màn hình chính: auth, court, social, manager...
├─ services/                 # Tầng API: booking, payment, recommender, chat...
├─ models/                   # Data models & view models
├─ themes/                   # Chủ đề màu sắc, typography
├─ utils/                    # Helpers, formatters
assets/images/               # Logo, hình ảnh giao diện
docs/                        # Tài liệu luồng nghiệp vụ & ML
recommender_system/          # Mã Python huấn luyện & artifact recommender
```

## Quy ước & best practices
- Tách API/service trong `lib/services`, không gọi trực tiếp HTTP từ widget.
- Dùng `Provider` cho state chia sẻ; tránh logic nặng trong widget build.
- Biến môi trường đọc qua `flutter_dotenv`; không commit file `.env`.
- Luồng booking luôn kiểm tra trùng slot qua server trước khi tạo/giữ chỗ.
- Không bọc `import` bằng try/catch (tuân thủ chuẩn mã). 

## Kiểm thử & chất lượng mã
- `flutter analyze` để phát hiện lint/cảnh báo.
- Bổ sung kiểm thử UI/unit nếu thêm logic mới (chưa bao gồm trong repo hiện tại).

## Đóng góp
1) Fork hoặc tạo branch theo chuẩn `feature/<ten>`.
2) Thực hiện thay đổi, đảm bảo tài liệu/cấu hình đi kèm được cập nhật.
3) Chạy kiểm tra cần thiết (lint/analyze), sau đó mở Pull Request mô tả rõ thay đổi và ảnh chụp UI (nếu có). 
