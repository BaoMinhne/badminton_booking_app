import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../../models/chat_contact.dart';
import '../../../models/chat_message.dart';
import '../../../models/chat_room.dart';
import '../../../services/chat_service.dart';
import '../../../services/user_service.dart';

class ChatManager with ChangeNotifier {
  ChatManager()
      : _chatService = ChatService(),
        _userService = UserDetailsService();

  final ChatService _chatService;
  final UserDetailsService _userService;

  bool _isLoadingRooms = false;
  final Map<String, bool> _loadingMessages = {};
  final Map<String, List<ChatMessage>> _messagesByRoom = {};
  List<ChatRoom> _rooms = [];
  String? _currentUserId;
  String? _error;

  bool get isLoadingRooms => _isLoadingRooms;
  String? get errorMessage => _error;

  UnmodifiableListView<ChatRoom> get rooms =>
      UnmodifiableListView<ChatRoom>(_rooms);

  List<ChatMessage> messagesForRoom(String roomId) =>
      _messagesByRoom[roomId] ?? const <ChatMessage>[];

  bool isLoadingMessages(String roomId) => _loadingMessages[roomId] ?? false;

  Future<void> refreshRooms() async {
    _isLoadingRooms = true;
    notifyListeners();
    try {
      _currentUserId ??= await _userService.getCurrentUserId();
      _rooms = await _chatService.fetchRooms();
      _error = null;
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoadingRooms = false;
      notifyListeners();
    }
  }

  List<ChatContact> get activeChats {
    return _rooms
        .map((room) => room.toChatContact(_currentUserId))
        .whereType<ChatContact>()
        .toList(growable: false);
  }

  Future<ChatRoom> ensureRoom(String userId) async {
    final room = await _chatService.ensureRoom(userId);
    await refreshRooms();
    return room;
  }

  Future<void> loadMessages(String roomId) async {
    _loadingMessages[roomId] = true;
    notifyListeners();
    try {
      _messagesByRoom[roomId] = await _chatService.fetchMessages(roomId);
      await _chatService.markMessagesAsRead(roomId);
      _error = null;
    } catch (error) {
      _error = error.toString();
    } finally {
      _loadingMessages[roomId] = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String roomId, String content) async {
    try {
      final message = await _chatService.sendMessage(
        roomId: roomId,
        content: content,
      );
      final messages = List<ChatMessage>.from(_messagesByRoom[roomId] ?? const []);
      messages.add(message);
      _messagesByRoom[roomId] = messages;
      await refreshRooms();
    } catch (error) {
      _error = error.toString();
      rethrow;
    }
  }
}
