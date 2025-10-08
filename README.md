# Badminton Booking App

Ứng dụng Flutter hỗ trợ đặt sân cầu lông, kết nối trực tiếp với PocketBase để
quản lý sân, người dùng và lịch đặt.

## Luồng đặt sân

* Người dùng chọn sân và ngày muốn chơi. Lưới thời gian hiển thị các sân con và
  phân biệt trạng thái bằng màu sắc: trắng (trống), đỏ (đã đặt hoặc chờ duyệt),
  xám (đang được người khác giữ chỗ) và xám đậm (khung giờ do bạn đang giữ).
* Khi chạm vào một khung giờ trống, ứng dụng gọi API `court_bookings` để tạo bản
  ghi với trạng thái `locked`. Khung giờ này được giữ tối đa 15 phút nhờ trường
  `locked_until`; trong thời gian đó người khác sẽ không thể chọn được.
* Người dùng nhấn **Gửi yêu cầu** để chuyển đặt chỗ sang trạng thái `pending`
  và chờ quản trị viên duyệt.
* Khi quản trị viên duyệt (trạng thái `confirmed`), nút **Thanh toán** sẽ mở
  trang Payment với đầy đủ thông tin sân, thời gian và trạng thái thanh toán.

Luồng này mô phỏng trải nghiệm tương tự ứng dụng AloBo: giữ chỗ tạm thời,
chờ duyệt, sau đó mới thanh toán.

## Vì sao không dùng SQLite trên thiết bị?

Việc giữ chỗ cần đảm bảo tính nhất quán theo thời gian thực cho toàn bộ người
chơi. Nếu lưu trạng thái bằng SQLite cục bộ thì mỗi thiết bị sẽ không biết được
các giữ chỗ của nhau, dẫn đến tình trạng overbooking. PocketBase đóng vai trò
là máy chủ trung tâm:

* Ghi nhận các bản ghi giữ chỗ (`locked`) cùng thời điểm hết hạn `locked_until`.
* Chỉ trả về các đặt chỗ còn hiệu lực khi truy vấn, đảm bảo người dùng khác không
  thể chọn vào khung giờ đã có người giữ.
* Cho phép quản trị viên thay đổi trạng thái (`pending`, `confirmed`,
  `cancelled`) và đồng bộ ngay lập tức tới tất cả thiết bị.

SQLite vẫn có thể sử dụng để cache dữ liệu đọc, nhưng việc khóa khung giờ bắt
buộc phải thực hiện ở server chung để đảm bảo tính toàn vẹn dữ liệu.

## Phụ thuộc

* Flutter 3.x
* [pocketbase](https://github.com/pocketbase/pocketbase)
* provider, shared_preferences, intl

## Chạy ứng dụng

```bash
flutter pub get
flutter run
```

Đảm bảo PocketBase đang chạy và biến môi trường `POCKETBASE_URL` đã được cấu
hình trong `.env`.
