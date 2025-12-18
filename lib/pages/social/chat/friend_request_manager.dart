import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../../models/friend_request.dart';
import '../../../services/friend_request_service.dart';
import '../../../services/pocketbase_client.dart';

class FriendRequestManager extends ChangeNotifier {
  FriendRequestManager() : _service = FriendRequestService();

  final FriendRequestService _service;

  List<FriendRequestItem> _incoming = const <FriendRequestItem>[];
  bool _isLoading = false;
  String? _error;
  final Map<String, bool> _actionLoading = {};
  UnsubscribeFunc? _unsubscribe;
  String? _currentUserId;

  List<FriendRequestItem> get incoming => _incoming;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool isProcessing(String requestId) => _actionLoading[requestId] == true;

  Future<void> initialize() async {
    await loadIncomingRequests();
    await _setupRealtime();
  }

  Future<void> loadIncomingRequests() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _incoming = await _service.fetchIncomingRequests();
      final pb = await getPocketbaseInstance();
      _currentUserId = pb.authStore.record?.id;
    } catch (err) {
      _error = 'Unable to load friend requests. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _setupRealtime() async {
    final pb = await getPocketbaseInstance();
    _currentUserId = pb.authStore.record?.id;
    final userId = _currentUserId;

    if (userId == null) return;

    final oldUnsub = _unsubscribe;
    _unsubscribe = null;
    if (oldUnsub != null) {
      await oldUnsub();
    }

    try {
      _unsubscribe = await pb
          .collection('friend_requests')
          .subscribe('*', _handleRealtimeEvent);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Failed to subscribe friend requests: $error');
      }
    }
  }

  Future<void> _handleRealtimeEvent(RecordSubscriptionEvent event) async {
    final record = event.record;
    final userId = _currentUserId;
    if (record == null || userId == null) return;

    final toUser = record.getStringValue('to_user');
    if (toUser != userId) return;

    switch (event.action) {
      case 'delete':
        _incoming = _incoming.where((req) => req.id != record.id).toList();
        break;
      case 'create':
      case 'update':
        final status = record.getStringValue('status');
        if (status != 'pending') {
          _incoming = _incoming.where((req) => req.id != record.id).toList();
          break;
        }

        final pb = await getPocketbaseInstance();
        final item = await _service.buildIncomingRequestItem(pb, record);
        if (item == null) break;

        final existingIndex =
            _incoming.indexWhere((element) => element.id == record.id);
        if (existingIndex == -1) {
          _incoming = <FriendRequestItem>[item, ..._incoming];
        } else {
          final mutable = [..._incoming];
          mutable[existingIndex] = item;
          _incoming = mutable;
        }
        break;
      default:
        break;
    }

    notifyListeners();
  }

  Future<void> accept(String requestId) async {
    _setProcessing(requestId, true);
    _error = null;
    try {
      final request = _incoming.firstWhere((element) => element.id == requestId);
      await _service.acceptFriendRequest(request);
      _incoming = _incoming.where((e) => e.id != requestId).toList();
    } catch (err) {
      _error = 'Unable to accept the request. Please try again.';
      rethrow;
    } finally {
      _setProcessing(requestId, false);
    }
  }

  Future<void> reject(String requestId) async {
    _setProcessing(requestId, true);
    _error = null;
    try {
      await _service.rejectFriendRequest(requestId);
      _incoming = _incoming.where((e) => e.id != requestId).toList();
    } catch (err) {
      _error = 'Unable to decline the request. Please try again.';
      rethrow;
    } finally {
      _setProcessing(requestId, false);
    }
  }

  void _setProcessing(String requestId, bool value) {
    _actionLoading[requestId] = value;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_unsubscribe?.call());
    super.dispose();
  }
}
