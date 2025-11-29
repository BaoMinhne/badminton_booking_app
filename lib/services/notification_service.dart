import 'package:pocketbase/pocketbase.dart';

import '../models/app_notification.dart';
import 'pocketbase_client.dart';

class NotificationService {
  static const collection = 'notifications';

  Future<List<AppNotification>> fetchNotifications({
    int page = 1,
    int perPage = 50,
  }) async {
    final pb = await getPocketbaseInstance();
    final currentUserId = pb.authStore.record?.id;

    if (currentUserId == null) {
      throw Exception('Bạn chưa đăng nhập.');
    }

    final result = await pb.collection(collection).getList(
          page: page,
          perPage: perPage,
          filter: "user = '$currentUserId'",
          sort: '-created',
          expand: 'sender',
        );

    return result.items
        .map((record) => AppNotification.fromRecord(record))
        .toList();
  }

  Future<void> markAsRead(String notificationId) async {
    final pb = await getPocketbaseInstance();
    await pb.collection(collection).update(notificationId, body: {
      'is_read': true,
      'read_at': DateTime.now().toIso8601String(),
    });
  }
}
