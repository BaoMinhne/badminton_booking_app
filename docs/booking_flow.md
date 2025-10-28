# Luồng đặt sân và lý do không sử dụng SQLite

## Giữ chỗ 15 phút và đồng bộ thời gian thực
Ứng dụng sử dụng `BookingService` để thao tác với collection `court_bookings` trên PocketBase. Mỗi khi người dùng chọn một ô trên lưới thời gian, ứng dụng gọi `lockSlot` để tạo bản ghi có trạng thái `locked` cùng trường `locked_until` sau 15 phút. Các slot đang được giữ được hiển thị trực tiếp trên component `CourtTimeline` nhờ dữ liệu trả về từ máy chủ, bảo đảm người dùng khác không thể chọn trùng.【F:lib/services/booking_service.dart†L20-L101】【F:lib/components/my_court_time.dart†L12-L397】

## Gửi yêu cầu duyệt và thanh toán
Sau khi hoàn tất lựa chọn, người dùng sử dụng nút "Gửi yêu cầu đặt sân" để chuyển toàn bộ các bản ghi `locked` sang trạng thái `pending`. Khi quản trị viên duyệt (`confirmed`), các lượt đặt sân sẽ xuất hiện trong màn hình thanh toán, nơi người dùng xem tổng thời gian và chi phí trước khi xác nhận thanh toán.【F:lib/pages/court/booking_page.dart†L1-L403】【F:lib/pages/court/payment_page.dart†L1-L198】

## Vì sao không dùng SQLite?
SQLite là cơ sở dữ liệu cục bộ trên thiết bị, thiếu cơ chế khóa và đồng bộ đa thiết bị. Nếu lưu giữ trạng thái giữ chỗ 15 phút bằng SQLite, mỗi điện thoại sẽ có dữ liệu riêng, dẫn đến việc hai người dùng có thể đặt trùng slot mà không biết nhau. PocketBase (hoặc các dịch vụ máy chủ tương tự) cung cấp API trung tâm, hỗ trợ bảo toàn giao dịch, xác thực người dùng và cập nhật thời gian thực, đáp ứng yêu cầu giữ chỗ và phê duyệt từ phía quản trị viên. Do đó, sử dụng SQLite cho bài toán này là không phù hợp.【F:lib/services/booking_service.dart†L20-L101】
