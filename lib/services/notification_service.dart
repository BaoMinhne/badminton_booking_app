import 'package:pocketbase/pocketbase.dart';

import '../models/app_notification.dart';
import 'pocketbase_client.dart';

class NotificationService {
  static const collection = 'notifications';

  UnsubscribeFunc? _unsubscribe;

  Future<List<AppNotification>> fetchCurrentUserNotifications({
    bool? unreadOnly,
    int page = 1,
    int perPage = 50,
  }) async {
    final pb = await getPocketbaseInstance();
    final currentUserId = pb.authStore.record?.id;
    if (currentUserId == null) {
      throw Exception('Bạn chưa đăng nhập.');
    }

    final filterBuffer = StringBuffer("user='${_escape(currentUserId)}'");
    if (unreadOnly != null) {
      filterBuffer.write(" && is_read = ${unreadOnly ? 'false' : 'true'}");
    }

    final result = await pb.collection(collection).getList(
          page: page,
          perPage: perPage,
          filter: filterBuffer.toString(),
          sort: '-created',
        );

    return result.items
        .map(AppNotification.fromRecord)
        .toList(growable: false);
  }

  Future<void> markAsRead(String notificationId) async {
    final pb = await getPocketbaseInstance();
    await pb.collection(collection).update(notificationId, body: {
      'is_read': true,
      'read_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> markAllAsRead() async {
    final pb = await getPocketbaseInstance();
    final currentUserId = pb.authStore.record?.id;
    if (currentUserId == null) return;

    final unreadList = await pb.collection(collection).getFullList(
          filter: "user='${_escape(currentUserId)}' && is_read = false",
          sort: '-created',
        );

    for (final item in unreadList) {
      await pb.collection(collection).update(item.id, body: {
        'is_read': true,
        'read_at': DateTime.now().toUtc().toIso8601String(),
      });
    }
  }

  Future<UnsubscribeFunc> subscribeForCurrentUser({
    required void Function(AppNotification notification) onChanged,
  }) async {
    final pb = await getPocketbaseInstance();
    final currentUserId = pb.authStore.record?.id;
    if (currentUserId == null) {
      throw Exception('Bạn chưa đăng nhập.');
    }

    await _unsubscribe?.call();

    _unsubscribe = await pb.collection(collection).subscribe(
          '*',
          (event) {
            final record = event.record;
            if (record == null) return;
            if (event.action != 'create' && event.action != 'update') return;
            onChanged(AppNotification.fromRecord(record));
          },
          filter: "user='${_escape(currentUserId)}'",
        );

    return _unsubscribe!;
  }

  Future<void> dispose() async {
    final unsub = _unsubscribe;
    _unsubscribe = null;
    if (unsub != null) {
      await unsub();
    }
  }

  Future<RecordModel> createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String body,
    NotificationTargetType? targetType,
    Map<String, dynamic>? payload,
    String? senderId,
  }) async {
    final pb = await getPocketbaseInstance();
    final resolvedSender = senderId ?? pb.authStore.record?.id;

    return pb.collection(collection).create(body: {
      'user': userId,
      if (resolvedSender != null) 'sender': resolvedSender,
      'type': type.value,
      'title': title,
      'body': body,
      if (targetType != null) 'target_type': targetType.value,
      'payload': payload ?? const {},
      'is_read': false,
    });
  }

  Future<void> createBookingSuccess({
    required String userId,
    required String bookingId,
    String? bookingLabel,
    String? senderId,
  }) async {
    await createNotification(
      userId: userId,
      senderId: senderId,
      type: NotificationType.bookingSuccess,
      title: 'Đặt sân thành công',
      body: bookingLabel ?? 'Lịch đặt sân của bạn đã được xác nhận.',
      targetType: NotificationTargetType.booking,
      payload: {
        'bookingId': bookingId,
      },
    );
  }

  Future<void> createBookingCancelled({
    required String userId,
    required String bookingId,
    String? reason,
    String? senderId,
  }) async {
    await createNotification(
      userId: userId,
      senderId: senderId,
      type: NotificationType.bookingCancelled,
      title: 'Đặt sân bị hủy',
      body: reason ?? 'Lịch đặt sân của bạn đã bị hủy.',
      targetType: NotificationTargetType.booking,
      payload: {
        'bookingId': bookingId,
        if (reason != null) 'reason': reason,
      },
    );
  }

  Future<void> createPostCommented({
    required String postOwnerId,
    required String postId,
    required String commentId,
    String? commenterId,
  }) async {
    await createNotification(
      userId: postOwnerId,
      senderId: commenterId,
      type: NotificationType.postCommented,
      title: 'Có bình luận mới',
      body: 'Ai đó đã bình luận vào bài viết của bạn.',
      targetType: NotificationTargetType.post,
      payload: {
        'postId': postId,
        'commentId': commentId,
      },
    );
  }

  Future<void> createPostLiked({
    required String postOwnerId,
    required String postId,
    String? likerId,
  }) async {
    await createNotification(
      userId: postOwnerId,
      senderId: likerId,
      type: NotificationType.postLiked,
      title: 'Bài viết được thích',
      body: 'Bài viết của bạn vừa nhận được lượt thích.',
      targetType: NotificationTargetType.post,
      payload: {
        'postId': postId,
      },
    );
  }

  Future<void> createRecruitmentApplied({
    required String ownerId,
    required String recruitmentPostId,
    required String applicantId,
    String? applicationId,
  }) async {
    await createNotification(
      userId: ownerId,
      senderId: applicantId,
      type: NotificationType.recruitmentApplied,
      title: 'Có yêu cầu tham gia mới',
      body: 'Một người chơi muốn tham gia đội của bạn.',
      targetType: NotificationTargetType.recruitmentPost,
      payload: {
        'recruitmentPostId': recruitmentPostId,
        if (applicationId != null) 'applicationId': applicationId,
      },
    );
  }

  Future<void> createRecruitmentStatusChanged({
    required String applicantId,
    required String recruitmentPostId,
    required String status,
    String? reviewerId,
    String? applicationId,
  }) async {
    await createNotification(
      userId: applicantId,
      senderId: reviewerId,
      type: NotificationType.recruitmentStatusChanged,
      title: status == 'accepted'
          ? 'Yêu cầu tham gia được chấp nhận'
          : 'Yêu cầu tham gia bị từ chối',
      body: status == 'accepted'
          ? 'Bạn đã được duyệt tham gia đội.'
          : 'Yêu cầu tham gia đã bị từ chối.',
      targetType: NotificationTargetType.recruitmentApplicant,
      payload: {
        'recruitmentPostId': recruitmentPostId,
        'status': status,
        if (applicationId != null) 'applicationId': applicationId,
      },
    );
  }

  Future<void> createFriendRequestReceived({
    required String receiverId,
    required String requestId,
    required String senderId,
  }) async {
    await createNotification(
      userId: receiverId,
      senderId: senderId,
      type: NotificationType.friendRequestReceived,
      title: 'Bạn có lời mời kết bạn',
      body: 'Có người vừa gửi lời mời kết bạn.',
      targetType: NotificationTargetType.friendRequest,
      payload: {
        'requestId': requestId,
      },
    );
  }

  Future<void> createFriendRequestAccepted({
    required String senderId,
    required String receiverId,
    required String requestId,
    bool accepted = true,
  }) async {
    await createNotification(
      userId: senderId,
      senderId: receiverId,
      type: accepted
          ? NotificationType.friendRequestAccepted
          : NotificationType.friendRequestRejected,
      title: accepted
          ? 'Lời mời kết bạn đã được chấp nhận'
          : 'Lời mời kết bạn bị từ chối',
      body: accepted
          ? 'Hai bạn giờ đã là bạn bè.'
          : 'Lời mời kết bạn của bạn đã bị từ chối.',
      targetType: NotificationTargetType.friendRequest,
      payload: {
        'requestId': requestId,
        'accepted': accepted,
      },
    );
  }

  String _escape(String value) => value.replaceAll("'", "\\'");
}
