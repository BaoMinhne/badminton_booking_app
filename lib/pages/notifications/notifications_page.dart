import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/app_notification.dart';
import 'notification_manager.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NotificationManager()..initialize(),
      child: const _NotificationsView(),
    );
  }
}

class _NotificationsView extends StatefulWidget {
  const _NotificationsView();

  @override
  State<_NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<_NotificationsView> {
  final _dateFormat = DateFormat('HH:mm dd/MM');

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<NotificationManager>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          IconButton(
            tooltip: 'Đánh dấu tất cả đã đọc',
            onPressed: manager.hasUnread && !manager.isMarkingAllRead
                ? () => manager.markAllAsRead()
                : null,
            icon: manager.isMarkingAllRead
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: cs.onPrimary,
                    ),
                  )
                : const Icon(Icons.done_all),
          ),
          PopupMenuButton<bool>(
            initialValue: manager.showUnreadOnly,
            icon: const Icon(Icons.filter_list),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: false,
                child: Text('Tất cả thông báo'),
              ),
              PopupMenuItem(
                value: true,
                child: Text('Chưa đọc'),
              ),
            ],
            onSelected: manager.toggleUnreadFilter,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: manager.loadNotifications,
          child: Builder(
            builder: (context) {
              if (manager.isLoading && manager.notifications.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (manager.errorMessage != null &&
                  manager.notifications.isEmpty) {
                return _ErrorState(
                  message: manager.errorMessage!,
                  onRetry: manager.loadNotifications,
                );
              }

              if (manager.notifications.isEmpty) {
                return const _EmptyState();
              }

              return ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final item = manager.notifications[index];
                  return _NotificationTile(
                    notification: item,
                    dateFormat: _dateFormat,
                    onTap: () => _onNotificationTap(manager, item),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemCount: manager.notifications.length,
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _onNotificationTap(
    NotificationManager manager,
    AppNotification notification,
  ) async {
    await manager.markAsRead(notification.id);

    if (!mounted) return;
    final context = this.context;

    final destinationDescription = _describeDestination(notification);
    if (destinationDescription != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(destinationDescription)),
      );
    }
  }

  String? _describeDestination(AppNotification notification) {
    switch (notification.targetType) {
      case NotificationTargetType.booking:
        return 'Đi tới chi tiết đặt sân: ${notification.payload['bookingId'] ?? ''}';
      case NotificationTargetType.post:
        return 'Mở bài viết: ${notification.payload['postId'] ?? ''}';
      case NotificationTargetType.recruitmentPost:
        return 'Xem bài tuyển: ${notification.payload['recruitmentPostId'] ?? ''}';
      case NotificationTargetType.recruitmentApplicant:
        return 'Xem yêu cầu tham gia của bạn';
      case NotificationTargetType.friendRequest:
        return 'Xử lý lời mời kết bạn';
      case NotificationTargetType.userProfile:
        return 'Mở trang cá nhân người gửi';
      case NotificationTargetType.chat:
        return 'Mở đoạn chat liên quan';
      case null:
        return null;
    }
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.dateFormat,
    required this.onTap,
  });

  final AppNotification notification;
  final DateFormat dateFormat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isRead = notification.isRead;

    return Material(
      color: isRead ? cs.surface : cs.primaryContainer.withOpacity(0.3),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LeadingIcon(notification: notification),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight:
                                  isRead ? FontWeight.w600 : FontWeight.w700,
                              fontSize: 16,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                        Text(
                          dateFormat.format(notification.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        color: cs.onSurface.withOpacity(0.8),
                      ),
                    ),
                    if (!isRead) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: cs.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Chưa đọc',
                            style: TextStyle(
                              color: cs.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeadingIcon extends StatelessWidget {
  const _LeadingIcon({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final data = _iconDataFor(notification.type);

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: data.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(data.icon, color: data.iconColor),
    );
  }

  _IconMeta _iconDataFor(NotificationType type) {
    switch (type) {
      case NotificationType.bookingSuccess:
        return _IconMeta(
          icon: Icons.event_available,
          background: Colors.green.shade50,
          iconColor: Colors.green.shade700,
        );
      case NotificationType.bookingCancelled:
        return _IconMeta(
          icon: Icons.event_busy,
          background: Colors.red.shade50,
          iconColor: Colors.red.shade700,
        );
      case NotificationType.postCommented:
        return _IconMeta(
          icon: Icons.mode_comment_outlined,
          background: Colors.blue.shade50,
          iconColor: Colors.blue.shade700,
        );
      case NotificationType.postLiked:
        return _IconMeta(
          icon: Icons.favorite_border,
          background: Colors.pink.shade50,
          iconColor: Colors.pink.shade700,
        );
      case NotificationType.recruitmentApplied:
        return _IconMeta(
          icon: Icons.group_add_outlined,
          background: Colors.orange.shade50,
          iconColor: Colors.orange.shade700,
        );
      case NotificationType.recruitmentStatusChanged:
        return const _IconMeta(
          icon: Icons.fact_check_outlined,
          background: Color(0xFFE3F2FD),
          iconColor: Color(0xFF1565C0),
        );
      case NotificationType.friendRequestReceived:
        return _IconMeta(
          icon: Icons.person_add_alt_1,
          background: Colors.purple.shade50,
          iconColor: Colors.purple.shade700,
        );
      case NotificationType.friendRequestAccepted:
        return _IconMeta(
          icon: Icons.handshake,
          background: Colors.teal.shade50,
          iconColor: Colors.teal.shade700,
        );
      case NotificationType.friendRequestRejected:
        return _IconMeta(
          icon: Icons.block,
          background: Colors.grey.shade200,
          iconColor: Colors.grey.shade800,
        );
    }
  }
}

class _IconMeta {
  const _IconMeta({
    required this.icon,
    required this.background,
    required this.iconColor,
  });

  final IconData icon;
  final Color background;
  final Color iconColor;
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 72, color: cs.primary),
            const SizedBox(height: 12),
            Text(
              'Chưa có thông báo nào',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Khi có cập nhật mới, thông báo sẽ xuất hiện ở đây ngay lập tức.',
              style: TextStyle(color: cs.onSurface.withOpacity(0.7)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, size: 64, color: cs.error),
            const SizedBox(height: 12),
            Text(
              'Không tải được thông báo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: cs.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: cs.onSurface.withOpacity(0.7)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
