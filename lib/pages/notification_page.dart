import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_notification.dart';
import '../pages/user/user_manager.dart';
import '../services/notification_service.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final _service = NotificationService();
  List<AppNotification> _items = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await _service.fetchNotifications();
      if (!mounted) return;
      setState(() {
        _items = items;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(AppNotification item) async {
    if (item.isRead) return;

    setState(() {
      _items = _items
          .map(
            (n) => n.id == item.id
                ? n.copyWith(isRead: true, readAt: DateTime.now())
                : n,
          )
          .toList();
    });

    try {
      await _service.markAsRead(item.id);
    } catch (_) {
      // Fail silently; UI already updated optimistically.
    }
  }

  @override
  Widget build(BuildContext context) {
    final userManager = context.watch<UserManager>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchNotifications,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _ErrorView(message: _error!, onRetry: _fetchNotifications)
                  : _items.isEmpty
                      ? _EmptyView(username: userManager.currentUser?.username)
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          itemBuilder: (_, index) => _NotificationTile(
                            notification: _items[index],
                            colorScheme: cs,
                            onTap: _markAsRead,
                          ),
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemCount: _items.length,
                        ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final ColorScheme colorScheme;
  final void Function(AppNotification) onTap;

  const _NotificationTile({
    required this.notification,
    required this.colorScheme,
    required this.onTap,
  });

  IconData _iconForType(String type) {
    switch (type) {
      case 'booking_success':
        return Icons.event_available_rounded;
      case 'booking_cancelled':
        return Icons.event_busy_rounded;
      case 'post_commented':
        return Icons.mode_comment_rounded;
      case 'post_liked':
        return Icons.favorite_border_rounded;
      case 'recruitment_applied':
        return Icons.group_add_rounded;
      case 'recruitment_status_changed':
        return Icons.cached_rounded;
      case 'friend_request_received':
        return Icons.person_add_alt_1_rounded;
      case 'friend_request_accepted':
        return Icons.handshake_rounded;
      case 'friend_request_rejected':
        return Icons.person_remove_alt_1_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    final icon = _iconForType(notification.type);

    return InkWell(
      onTap: () => onTap(notification),
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUnread
              ? colorScheme.primary.withOpacity(0.06)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isUnread
                ? colorScheme.primary.withOpacity(0.3)
                : Colors.grey.shade200,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notification.displayTitle,
                          style: TextStyle(
                            fontWeight:
                                isUnread ? FontWeight.w800 : FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  if (notification.displayBody.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      notification.displayBody,
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.75),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.schedule,
                          size: 14, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text(
                        notification.timeLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String? username;
  const _EmptyView({this.username});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final greeting = username == null || username!.isEmpty
        ? 'Chào bạn!'
        : 'Chào $username!';
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_off_rounded,
                size: 64, color: cs.onSurface.withOpacity(0.4)),
            const SizedBox(height: 14),
            Text(
              'Chưa có thông báo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$greeting Hiện chưa có thông báo mới. Khi có hoạt động, thông báo sẽ xuất hiện ở đây.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cs.onSurface.withOpacity(0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 56, color: cs.error.withOpacity(0.8)),
            const SizedBox(height: 12),
            Text(
              'Không tải được thông báo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cs.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
