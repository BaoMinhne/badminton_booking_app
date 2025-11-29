import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../models/app_notification.dart';
import '../../services/notification_service.dart';

class NotificationManager with ChangeNotifier {
  NotificationManager({NotificationService? notificationService})
      : _notificationService = notificationService ?? NotificationService();

  final NotificationService _notificationService;

  List<AppNotification> _items = const [];
  bool _isLoading = false;
  bool _showUnreadOnly = false;
  String? _errorMessage;
  bool _isMarkingAllRead = false;
  UnsubscribeFunc? _unsubscribe;

  List<AppNotification> get notifications => _showUnreadOnly
      ? _items.where((n) => !n.isRead).toList(growable: false)
      : List.unmodifiable(_items);

  bool get isLoading => _isLoading;
  bool get showUnreadOnly => _showUnreadOnly;
  String? get errorMessage => _errorMessage;
  bool get isMarkingAllRead => _isMarkingAllRead;
  bool get hasUnread => _items.any((n) => !n.isRead);

  Future<void> initialize() async {
    await loadNotifications();
    await _subscribeRealtime();
  }

  Future<void> loadNotifications() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final records = await _notificationService.fetchCurrentUserNotifications(
        unreadOnly: _showUnreadOnly ? true : null,
        perPage: 100,
      );
      _items = List<AppNotification>.from(records)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleUnreadFilter(bool value) async {
    if (_showUnreadOnly == value) return;
    _showUnreadOnly = value;
    await loadNotifications();
  }

  Future<void> markAsRead(String notificationId) async {
    final index = _items.indexWhere((n) => n.id == notificationId);
    if (index == -1 || _items[index].isRead) return;

    final updated = _items[index];
    _items[index] = AppNotification(
      id: updated.id,
      userId: updated.userId,
      senderId: updated.senderId,
      type: updated.type,
      title: updated.title,
      body: updated.body,
      targetType: updated.targetType,
      payload: updated.payload,
      isRead: true,
      createdAt: updated.createdAt,
      readAt: DateTime.now(),
    );
    notifyListeners();

    try {
      await _notificationService.markAsRead(notificationId);
    } catch (_) {
      // If update fails, we silently ignore; realtime will resync.
    }
  }

  Future<void> markAllAsRead() async {
    if (_isMarkingAllRead) return;
    _isMarkingAllRead = true;
    notifyListeners();

    try {
      await _notificationService.markAllAsRead();
      _items = _items
          .map(
            (n) => AppNotification(
              id: n.id,
              userId: n.userId,
              senderId: n.senderId,
              type: n.type,
              title: n.title,
              body: n.body,
              targetType: n.targetType,
              payload: n.payload,
              isRead: true,
              createdAt: n.createdAt,
              readAt: n.readAt ?? DateTime.now(),
            ),
          )
          .toList(growable: false);
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isMarkingAllRead = false;
      notifyListeners();
    }
  }

  Future<void> _subscribeRealtime() async {
    await _unsubscribe?.call();

    try {
      _unsubscribe = await _notificationService.subscribeForCurrentUser(
        onChanged: _onNotificationChanged,
      );
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
    }
  }

  void _onNotificationChanged(AppNotification notification) {
    final index = _items.indexWhere((n) => n.id == notification.id);
    if (index >= 0) {
      _items[index] = notification;
    } else {
      _items = [notification, ..._items];
    }
    _items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  @override
  void dispose() {
    _unsubscribe?.call();
    super.dispose();
  }
}
