import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../../models/chat_contact.dart';
import '../../../models/chat_room.dart';
import '../../../services/chat_service.dart';
import '../../../services/pocketbase_client.dart';

class ChatListManager extends ChangeNotifier {
  ChatListManager() : _service = ChatService();

  final ChatService _service;

  List<ChatContact> _chats = const <ChatContact>[];
  bool _isLoading = false;
  String? _error;
  UnsubscribeFunc? _roomUnsubscribe;
  String? _currentUserId;

  List<ChatContact> get chats => _chats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> initialize() async {
    await loadChats();
    await _setupRealtime();
  }

  Future<void> loadChats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final rooms = await _service.fetchRooms();
      final pb = await getPocketbaseInstance();
      _currentUserId = pb.authStore.record?.id;
      _chats = _mapRoomsToContacts(rooms);
    } catch (error) {
      _error = 'Không thể tải danh sách trò chuyện. Vui lòng thử lại.';
      if (kDebugMode) {
        debugPrint('Load chats failed: $error');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _setupRealtime() async {
    if (_currentUserId == null) {
      final pb = await getPocketbaseInstance();
      _currentUserId = pb.authStore.record?.id;
    }
    final userId = _currentUserId;
    if (userId == null) return;

    try {
      final oldUnsub = _roomUnsubscribe;
      _roomUnsubscribe = null;
      if (oldUnsub != null) {
        await oldUnsub();
      }

      _roomUnsubscribe = await _service.subscribeRooms(userId, _handleRoomEvent);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Failed to subscribe rooms: $error');
      }
    }
  }

  Future<void> _handleRoomEvent(RecordSubscriptionEvent event) async {
    final record = event.record;
    final userId = _currentUserId;
    if (record == null || userId == null) return;

    final room = ChatRoom.fromRecord(record, currentUserId: userId);
    final updatedContact = room.toContact(userId);

    switch (event.action) {
      case 'delete':
        _chats = _chats.where((c) => c.chatId != room.id && c.id != room.id).toList();
        break;
      case 'create':
      case 'update':
        _upsertContact(updatedContact);
        break;
      default:
        break;
    }

    notifyListeners();
  }

  void _upsertContact(ChatContact contact) {
    final index = _chats.indexWhere((element) =>
        (element.chatId ?? element.id) == (contact.chatId ?? contact.id));
    if (index == -1) {
      _chats = <ChatContact>[contact, ..._chats];
    } else {
      final mutable = [..._chats];
      mutable[index] = contact;
      _chats = mutable;
    }
  }

  List<ChatContact> _mapRoomsToContacts(List<ChatRoom> rooms) {
    final userId = _currentUserId;
    if (userId == null) return const <ChatContact>[];

    return rooms.map((room) => room.toContact(userId)).toList();
  }

  @override
  void dispose() {
    unawaited(_roomUnsubscribe?.call());
    super.dispose();
  }
}
