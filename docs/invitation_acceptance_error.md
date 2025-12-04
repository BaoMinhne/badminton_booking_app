# Lý do lỗi khi chấp nhận lời mời tuyển thành viên

Luồng `InvitationService.respond` luôn **cập nhật trạng thái lời mời trước** rồi mới thêm người dùng vào danh sách ứng viên bài tuyển dụng thông qua `_upsertRecruitmentApplicant`. Nếu bước thêm ứng viên gặp lỗi (ví dụ: PocketBase trả về lỗi ràng buộc vì bản ghi đã tồn tại hoặc lỗi quyền), hàm sẽ ném `InvitationServiceException` mặc dù việc cập nhật trạng thái lời mời đã hoàn tất. Kết quả là bạn thấy lời mời đã chuyển sang "accepted" trong hệ thống, nhưng UI vẫn báo lỗi.

Nguồn gốc lỗi nằm ở logic `_upsertRecruitmentApplicant` trong `lib/services/invitation_service.dart`: hàm thực hiện truy vấn hoặc tạo mới bản ghi ứng viên, và bất kỳ lỗi `ClientException` nào chưa được xử lý sẽ bị chuyển đổi thành `InvitationServiceException`, khiến luồng `respond` báo lỗi sau khi đã cập nhật lời mời. Bạn cần đảm bảo bước upsert không ném lỗi (hoặc đổi thứ tự xử lý) để tránh tình trạng cập nhật nửa chừng này.
