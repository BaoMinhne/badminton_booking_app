# PocketBase Collections

Tệp cấu hình trong thư mục này mô tả schema cho các collection cần thiết của PocketBase.

## court_bookings

- **File:** `court_bookings.collection.json`
- **Mục đích:** Lưu trữ thông tin đặt sân bao gồm sân, sân con, người đặt, thời gian và trạng thái đặt sân.
- **Các bước import:**
  1. Đăng nhập vào trang quản trị PocketBase.
  2. Mở mục **Settings → Import collections**.
  3. Tải lên file `court_bookings.collection.json`.
  4. Kiểm tra lại rule và field sau khi import để đảm bảo phù hợp với nhu cầu vận hành thực tế.

Collection này yêu cầu người dùng đã đăng nhập để tạo lịch đặt sân. Chủ sân, quản lý hoặc admin có thể xem, cập nhật và xóa tất cả lịch đặt sân của sân thuộc quyền quản lý của họ.
