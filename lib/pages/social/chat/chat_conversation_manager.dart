import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../../models/chat_message.dart';
import '../../../services/chat_service.dart';
import '../../../services/pocketbase_client.dart';

class ChatConversationManager extends ChangeNotifier {
  ChatConversationManager({required this.chatId}) : _service = ChatService();

  final String chatId;
  final ChatService _service;

  List<ChatMessage> _messages = const <ChatMessage>[];
  bool _isLoading = false;
  String? _error;
  UnsubscribeFunc? _messagesUnsubscribe;
  String? _currentUserId;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> initialize() async {
    await _loadMessages();
    await _setupRealtime();
  }

  Future<void> _loadMessages() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final pb = await getPocketbaseInstance();
      _currentUserId = pb.authStore.record?.id;
      _messages = await _service.fetchMessages(chatId);
    } catch (error) {
      _error = 'Không thể tải tin nhắn. Vui lòng thử lại.';
      if (kDebugMode) {
        debugPrint('Load messages failed: $error');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _setupRealtime() async {
    try {
      final oldUnsub = _messagesUnsubscribe;
      _messagesUnsubscribe = null;
      if (oldUnsub != null) {
        await oldUnsub();
      }

      _messagesUnsubscribe = await _service.subscribeMessages(
        chatId,
        _handleMessageEvent,
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Subscribe messages failed: $error');
      }
    }
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    try {
      final message = await _service.sendMessage(chatId: chatId, content: trimmed);
      _upsertMessage(message);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Send message failed: $error');
      }
    }
  }

  Future<void> _handleMessageEvent(RecordSubscriptionEvent event) async {
    final record = event.record;
    if (record == null) return;
    if (event.action == 'delete') return;

    try {
      final userId =
          _currentUserId ?? (await getPocketbaseInstance()).authStore.record?.id;
      _currentUserId ??= userId;
      final current = ChatMessage.fromRecord(
        record,
        currentUserId: userId ?? '',
      );
      _upsertMessage(current);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Realtime refresh failed: $error');
      }
    }
  }

  void _upsertMessage(ChatMessage message) {
    final existingIndex = _messages.indexWhere((m) => m.id == message.id);
    if (existingIndex >= 0) {
      final mutable = [..._messages];
      mutable[existingIndex] = message;
      _messages = mutable;
    } else {
      _messages = [..._messages, message];
    }
    _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_messagesUnsubscribe?.call());
    super.dispose();
  }
}
