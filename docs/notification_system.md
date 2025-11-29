# Hệ thống thông báo realtime với PocketBase (v0.23.x) và Flutter

Tài liệu này mô tả thiết kế collection, rule, hook backend và cách tiêu thụ realtime trên Flutter để hiển thị thông báo kiểu Facebook.

## 1) Thiết kế collection `notifications`

Collection đã có các trường phù hợp. Nên bật `read_at.onUpdate = true` (hoặc bỏ tự động onCreate) để có thể lưu thời điểm người dùng đọc. Các chỉ số `idx_notifications_user_created` và `idx_notifications_user_is_read_created` đã hỗ trợ query/ sort cho màn hình thông báo.【F:lib/models/app_notification.dart†L1-L88】

**Quy ước giá trị**
- `type`: `booking_success`, `booking_cancelled`, `post_commented`, `post_liked`, `recruitment_applied`, `recruitment_status_changed`, `friend_request_received`, `friend_request_accepted`, `friend_request_rejected`.
- `target_type`: `booking`, `post`, `recruitment_post`, `recruitment_applicant`, `friend_request`, `user_profile`, `chat`.
- `payload`: JSON nhỏ chứa id liên quan (`bookingId`, `postId`, `requestId`, ...).【F:lib/models/app_notification.dart†L16-L48】【F:lib/models/app_notification.dart†L50-L86】

## 2) Rules của collection

| Rule            | Giá trị khuyến nghị                                                                                  | Giải thích |
|-----------------|------------------------------------------------------------------------------------------------------|------------|
| listRule/viewRule | `@request.auth.id = user`                                                                          | Chỉ chủ sở hữu nhận được thông báo của chính họ. |
| createRule      | `@request.auth.id = user || @request.auth.admin = true`                                              | Cho phép server-side hook (chạy bằng Admin) tạo thông báo, hoặc client tự push cho chính mình nếu cần. |
| updateRule      | `@request.auth.id = user && @request.data.is_read:isset = true`                                     | Cho phép người dùng chỉ đánh dấu đã đọc. |
| deleteRule      | `@request.auth.admin = true`                                                                         | Chỉ admin có quyền xóa hàng loạt. |

Nếu cần tạo thay mặt người khác từ server, hãy dùng Admin token hoặc chạy trong PocketBase hook (được bypass rule).

## 3) Hook backend tạo thông báo tự động

Ví dụ file `pb_hooks/notifications.js` (Node API của PocketBase). Các hook này chạy trong server nên không bị giới hạn bởi rules.

```js
/// Import từ SDK server có sẵn bên trong PocketBase
import { RecordService } from 'pocketbase';

async function notify(dao, body) {
  const service = new RecordService('notifications', dao);
  await service.create(body);
}

onRecordAfterCreate('court_bookings', async (e) => {
  if (e.record.get('status') === 'confirmed') {
    await notify(e.dao, {
      user: e.record.get('user_id'),
      type: 'booking_success',
      title: 'Đặt sân thành công',
      body: 'Lịch đặt sân của bạn đã được xác nhận.',
      target_type: 'booking',
      payload: { bookingId: e.record.id },
    });
  }
});

onRecordAfterUpdate('court_bookings', async (e) => {
  if (e.record.get('status') === 'cancelled') {
    await notify(e.dao, {
      user: e.record.get('user_id'),
      type: 'booking_cancelled',
      title: 'Đặt sân bị hủy',
      body: e.record.get('cancel_reason') ?? 'Lịch đặt sân của bạn đã bị hủy.',
      target_type: 'booking',
      payload: { bookingId: e.record.id },
    });
  }
});

onRecordAfterCreate('post_comments', async (e) => {
  await notify(e.dao, {
    user: e.record.get('post_owner_id'),
    sender: e.record.get('author_id'),
    type: 'post_commented',
    title: 'Có bình luận mới',
    body: 'Ai đó đã bình luận vào bài viết của bạn.',
    target_type: 'post',
    payload: { postId: e.record.get('post'), commentId: e.record.id },
  });
});

onRecordAfterCreate('post_reactions', async (e) => {
  await notify(e.dao, {
    user: e.record.get('post_owner_id'),
    sender: e.record.get('user'),
    type: 'post_liked',
    title: 'Bài viết được thích',
    body: 'Bài viết của bạn vừa nhận được lượt thích.',
    target_type: 'post',
    payload: { postId: e.record.get('post') },
  });
});

onRecordAfterCreate('recruitment_applicants', async (e) => {
  await notify(e.dao, {
    user: e.record.get('owner_id'),
    sender: e.record.get('applicant_id'),
    type: 'recruitment_applied',
    title: 'Có yêu cầu tham gia mới',
    body: 'Một người chơi muốn tham gia đội của bạn.',
    target_type: 'recruitment_post',
    payload: { recruitmentPostId: e.record.get('post'), applicationId: e.record.id },
  });
});

onRecordAfterUpdate('recruitment_applicants', async (e) => {
  const status = e.record.get('status');
  if (!['accepted', 'rejected'].includes(status)) return;
  await notify(e.dao, {
    user: e.record.get('applicant_id'),
    sender: e.record.get('reviewer_id'),
    type: 'recruitment_status_changed',
    title: status === 'accepted'
      ? 'Yêu cầu tham gia được chấp nhận'
      : 'Yêu cầu tham gia bị từ chối',
    body: status === 'accepted'
      ? 'Bạn đã được duyệt tham gia đội.'
      : 'Yêu cầu tham gia đã bị từ chối.',
    target_type: 'recruitment_applicant',
    payload: { recruitmentPostId: e.record.get('post'), status },
  });
});

onRecordAfterCreate('friend_requests', async (e) => {
  if (e.record.get('status') !== 'pending') return;
  await notify(e.dao, {
    user: e.record.get('to_user'),
    sender: e.record.get('from_user'),
    type: 'friend_request_received',
    title: 'Bạn có lời mời kết bạn',
    body: 'Có người vừa gửi lời mời kết bạn.',
    target_type: 'friend_request',
    payload: { requestId: e.record.id },
  });
});

onRecordAfterUpdate('friend_requests', async (e) => {
  if (!['accepted', 'rejected'].includes(e.record.get('status'))) return;
  await notify(e.dao, {
    user: e.record.get('from_user'),
    sender: e.record.get('to_user'),
    type: e.record.get('status') === 'accepted'
      ? 'friend_request_accepted'
      : 'friend_request_rejected',
    title: e.record.get('status') === 'accepted'
      ? 'Lời mời kết bạn đã được chấp nhận'
      : 'Lời mời kết bạn đã bị từ chối',
    body: e.record.get('status') === 'accepted'
      ? 'Hai bạn giờ đã là bạn bè.'
      : 'Lời mời kết bạn đã bị từ chối.',
    target_type: 'friend_request',
    payload: { requestId: e.record.id, status: e.record.get('status') },
  });
});
```

## 4) SDK Flutter: nhận realtime, đánh dấu đã đọc

Dùng `NotificationService` để lắng nghe realtime, lấy danh sách, đánh dấu đọc và tạo record khi chạy logic phía client (nếu không sử dụng hook).【F:lib/services/notification_service.dart†L1-L181】【F:lib/services/notification_service.dart†L183-L287】

```dart
final notificationService = NotificationService();

/// Lấy danh sách ban đầu (ví dụ hiển thị trong screen)
final items = await notificationService.fetchCurrentUserNotifications(
  unreadOnly: false,
  page: 1,
  perPage: 30,
);

/// Đăng ký realtime để UI tự cập nhật
await notificationService.subscribeForCurrentUser(
  onChanged: (notification) {
    // push vào state (Riverpod/BLoC/GetX) để build UI
  },
);

/// Đánh dấu một thông báo đã đọc
await notificationService.markAsRead(notification.id);

/// Đánh dấu tất cả đã đọc
await notificationService.markAllAsRead();
```

## 5) Ánh xạ điều hướng UI

`target_type` + `payload` giúp mở đúng màn hình:

- `booking` + `payload.bookingId` → màn hình chi tiết đặt sân.
- `post` + `payload.postId` → màn hình bài viết cộng đồng.
- `recruitment_post` / `recruitment_applicant` + `payload.recruitmentPostId` → màn hình tuyển thành viên hoặc đơn ứng tuyển.
- `friend_request` + `payload.requestId` → màn hình quản lý lời mời kết bạn.
- `chat` + `payload.roomId` → màn chat.

Khi người dùng chạm vào item, lấy `target_type` và `payload` để điều hướng rồi gọi `markAsRead`.
