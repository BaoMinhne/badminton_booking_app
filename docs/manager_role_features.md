# Chức năng dành cho chủ sân (Manager)

Bản thiết kế tính năng dành cho vai trò `manager` – người quản lý cụm sân. Hệ thống hiện tại tự động duyệt booking ngay sau thanh toán, vì vậy module này tập trung vào giám sát, xử lý ngoại lệ và vận hành sân (không có bước duyệt thủ công từng đơn).

## Nguyên tắc điều hướng & phân quyền
- Khi người dùng đăng nhập có `role = manager`, điều hướng thẳng đến khu vực quản trị chủ sân.
- Các tab chính: **Dashboard**, **Lịch đặt sân**, **Booking ngoại lệ**, **Booking offline**, **Sân & dịch vụ**, **Giờ & slot đặc biệt**, **Giá sân**, **Báo cáo**.
- Mọi thao tác thay đổi booking (hủy/đổi giờ/đổi sân/block slot) phải gọi backend để tái kiểm tra trùng slot.

## (1) Dashboard & Lịch đặt sân
- **Dashboard**: cards tổng quan (doanh thu hôm nay/tuần/tháng, tỷ lệ lấp đầy, tổng booking đã thanh toán, cảnh báo slot bị block). Dùng API analytics hoặc tổng hợp từ `confirmed` bookings.
- **Lịch đặt sân**: hai chế độ hiển thị
  - **Bảng**: bộ lọc theo ngày, sân, khung giờ; bảng có cột: sân, giờ bắt đầu–kết thúc, khách, SĐT, trạng thái (confirmed/offline/block), ghi chú.
  - **Calendar timeline**: mỗi sân là một hàng timeline, slot hiển thị màu theo trạng thái; hỗ trợ click để mở chi tiết booking.
- Bộ chọn ngày (date picker) mặc định hôm nay; cho phép nhảy nhanh tới ngày khác.

## (2) Quản lý booking (xử lý ngoại lệ)
- **Hủy booking**: form nhập lý do, gửi request hủy; backend gửi thông báo cho khách. Booking chuyển trạng thái `cancelled_by_manager`.
- **Đổi giờ/đổi sân**: màn sửa booking với bộ chọn ngày/giờ/sân; khi submit, backend kiểm tra trùng slot và trả booking mới.
- **Block slot**: chọn sân, ngày, khung giờ, lý do (bảo trì/giải đấu/đóng cửa); slot bị ẩn khỏi người dùng. Cho phép bỏ block.
- Nhật ký thao tác (audit log) hiển thị gần đây để dễ truy vết.

## (3) Tạo booking offline (khách vãng lai / khách quen)
- Form tạo nhanh gồm: tên khách, SĐT, ngày, giờ bắt đầu–kết thúc, sân, ghi chú, hình thức thanh toán (tiền mặt/chuyển khoản). 
- Booking offline tạo với trạng thái `confirmed` và flag `isOffline=true` để thống kê sau này; thanh toán được đánh dấu `paid_offline`.
- Hệ thống tái sử dụng endpoint tạo booking, nhưng bypass bước thanh toán online và gắn cờ offline.

## (4) Quản lý thông tin sân
- Trang chỉnh sửa thông tin chung: tên, địa chỉ, mô tả, SĐT, nội quy (rich text hoặc multiline).
- **Ảnh sân**: upload/đổi/xóa ảnh; xem trước ảnh hiện tại.
- **Dịch vụ đi kèm**: danh sách dịch vụ (giữ xe, khăn nước, thuê vợt...). Cho phép thêm/xóa/chỉnh sửa giá mô tả; hiển thị bật/tắt dịch vụ.

## (5) Giờ mở cửa & khung giờ đặc biệt
- **Lịch mở cửa**: cấu hình 7 ngày/tuần (giờ mở–đóng). Hiển thị preview để người quản lý biết slot hợp lệ cho booking.
- **Ngày nghỉ / đóng cửa đột xuất**: thêm ngày hoặc dải ngày không mở cửa; tất cả slot trong khoảng bị ẩn khỏi người dùng.
- **Khung giờ đặc biệt**: đánh dấu các dải thời gian dành cho giải đấu/thuê dài hạn; slot này chỉ hiện ở manager view và bị ẩn khỏi đặt mới.
- UI nên cho phép copy cấu hình từ một ngày sang ngày khác để thao tác nhanh.

## (6) Quản lý giá sân
- Bảng giá theo khung giờ và ngày trong tuần (map với `court_pricing` backend). 
- Mỗi entry gồm: sân hoặc loại sân, ngày áp dụng (thứ 2–CN hoặc ngày đặc biệt), khung giờ, giá, nhãn `cao điểm / thấp điểm`.
- Cho phép sắp xếp ưu tiên: giá đặc biệt > giá theo ngày > giá mặc định. Backend tính giá dựa trên quy tắc ưu tiên.
- Hỗ trợ nhân bản dòng giá để chỉnh nhanh các khung giờ gần giống.

## (7) Thống kê – báo cáo doanh thu
- Biểu đồ/đồ thị: doanh thu hôm nay/tuần/tháng; so sánh với kỳ trước.
- Tỷ lệ lấp đầy: số slot đã đặt / tổng slot mở, theo ngày và theo sân.
- Danh sách booking đã thanh toán (trạng thái `confirmed`) có thể lọc theo ngày/sân/kênh (online/offline).
- Xuất báo cáo CSV: doanh thu, booking offline vs online, hiệu suất từng sân.

## Đề xuất luồng UI
1. **Manager Home** (tab): chứa dashboard và lối tắt tới Lịch, Booking offline, Block slot, Giá.
2. **Lịch**: toggle bảng/timeline, bộ lọc ngày–sân–trạng thái. Mỗi booking mở modal chi tiết với hành động hủy/đổi/block.
3. **Booking offline**: form một bước, hiển thị cảnh báo khi trùng slot.
4. **Sân & dịch vụ**: danh sách sân; bấm vào sân để chỉnh thông tin, ảnh, dịch vụ.
5. **Giờ & slot đặc biệt**: bảng tuần + danh sách ngày nghỉ + danh sách khung giờ đặc biệt; nút thêm/sửa/xóa.
6. **Giá sân**: bảng giá, hỗ trợ import/export JSON để khớp backend `court_pricing`.
7. **Báo cáo**: thẻ KPI + biểu đồ đường/cột + bảng chi tiết có lọc và export.

## Logic & kỹ thuật gợi ý (Flutter)
- Tạo `ManagerModule` với `ChangeNotifier` hoặc `Riverpod` provider chứa:
  - `ManagerScheduleState` (lịch/booking), `ManagerCourtState` (thông tin sân, dịch vụ), `PricingState`, `AnalyticsState`.
  - Hàm helper dùng chung: `fetchSchedule(date)`, `blockSlot()`, `createOfflineBooking()`, `updatePricing()`, `fetchAnalytics(period)`.
- Component gợi ý:
  - `manager_dashboard_page.dart`: KPI cards + chart widgets.
  - `manager_schedule_page.dart`: toggle giữa `DataTable` và `TimelineView` (sử dụng `Syncfusion Calendar` hoặc custom `ListView` theo sân).
  - `booking_exception_sheet.dart`: modal cho hủy/đổi giờ/đổi sân/block.
  - `offline_booking_form.dart`: form + validator + gọi API tạo booking offline.
  - `court_profile_editor.dart`: form thông tin sân + gallery upload + dịch vụ.
  - `operating_hours_editor.dart`: chỉnh giờ mở cửa và khung giờ đặc biệt.
  - `pricing_editor.dart`: bảng giá với drag-to-copy khung giờ.
  - `reports_page.dart`: chart + export CSV (dùng `csv` package).
- Backend integration: thêm header `X-Manager-Context` hoặc dùng token có role `manager`; tất cả request phải truyền `courtGroupId` (cụm sân) để lấy đúng dữ liệu.
- Thông báo cho khách: khi hủy hoặc đổi, backend gửi push/SMS; UI chỉ hiển thị kết quả.

## Ma trận quyền & trạng thái
| Hành động | Trạng thái đầu vào | Trạng thái đầu ra | Ghi chú |
|---|---|---|---|
| Hủy booking | confirmed / offline | cancelled_by_manager | Gửi lý do hủy, thông báo khách |
| Đổi giờ/sân | confirmed / offline | confirmed (slot mới) | Backend kiểm tra trùng, trả về slot mới |
| Block slot | (slot trống) | blocked | Ẩn khỏi người dùng, hiện trong timeline với nhãn Blocked |
| Tạo offline | (slot trống) | confirmed + isOffline | Bypass thanh toán online, lưu payment method |

## Phần việc ưu tiên triển khai
1. Tạo navigation riêng cho `manager` với tab Dashboard – Lịch – Offline – Sân – Giá – Báo cáo.
2. Hoàn thiện API client: lịch, block slot, offline booking, pricing, analytics.
3. Dựng UI lịch (bảng + timeline), form offline booking, modal ngoại lệ.
4. Sau cùng bổ sung báo cáo và export CSV.
