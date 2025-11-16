import 'package:pocketbase/pocketbase.dart';

import '../models/chat_message.dart';
import '../models/chat_room.dart';
import 'pocketbase_client.dart';

class ChatServiceException implements Exception {
  ChatServiceException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ChatService {
  static const _rooms = 'room_chats';
  static const _messages = 'chat_messages';

  Future<String> _currentUserId(PocketBase pb) async {
    final userId = pb.authStore.record?.id;
    if (userId == null) {
      throw ChatServiceException('Bạn cần đăng nhập để sử dụng chat.');
    }
    return userId;
  }

  Future<List<ChatRoom>> fetchRooms({int page = 1, int perPage = 30}) async {
    final pb = await getPocketbaseInstance();
    final me = await _currentUserId(pb);
    final result = await pb.collection(_rooms).getList(
          page: page,
          perPage: perPage,
          filter: 'user_a = "$me" || user_b = "$me"',
          expand: 'user_a,user_b,last_sender',
          sort: '-last_message_at,-updated',
        );
    final rooms = result.items
        .map((record) => ChatRoom.fromRecord(record, pb))
        .toList(growable: false);

    final roomsWithUnread = await Future.wait(
      rooms.map((room) async {
        final unread = await fetchUnreadCount(room.id);
        return room.copyWith(unreadCount: unread);
      }),
    );
    return roomsWithUnread;
  }

  Future<ChatRoom> ensureRoom(String otherUserId) async {
    final pb = await getPocketbaseInstance();
    final me = await _currentUserId(pb);
    final pair = _sortedPair(me, otherUserId);
    try {
      final existing = await pb.collection(_rooms).getFirstListItem(
            'user_a = "${pair.$1}" && user_b = "${pair.$2}"',
            expand: 'user_a,user_b,last_sender',
          );
      final room = ChatRoom.fromRecord(existing, pb);
      final unread = await fetchUnreadCount(room.id);
      return room.copyWith(unreadCount: unread);
    } on ClientException catch (error) {
      if (error.statusCode != 404) rethrow;
    }

    final record = await pb.collection(_rooms).create(body: {
      'user_a': pair.$1,
      'user_b': pair.$2,
    });
    final expanded = await pb.collection(_rooms).getOne(
          record.id,
          expand: 'user_a,user_b,last_sender',
        );
    return ChatRoom.fromRecord(expanded, pb);
  }

  Future<List<ChatMessage>> fetchMessages(
    String roomId, {
    int page = 1,
    int perPage = 50,
  }) async {
    final pb = await getPocketbaseInstance();
    final me = await _currentUserId(pb);
    final result = await pb.collection(_messages).getList(
          page: page,
          perPage: perPage,
          filter: 'chat = "$roomId"',
          expand: 'sender',
          sort: 'created',
        );
    return result.items
        .map((record) => ChatMessage.fromRecord(record, me))
        .toList(growable: false);
  }

  Future<ChatMessage> sendMessage({
    required String roomId,
    required String content,
  }) async {
    if (content.trim().isEmpty) {
      throw ChatServiceException('Tin nhắn không được để trống.');
    }
    final pb = await getPocketbaseInstance();
    final me = await _currentUserId(pb);
    final record = await pb.collection(_messages).create(body: {
      'chat': roomId,
      'sender': me,
      'content': content.trim(),
      'is_read': false,
    });

    await pb.collection(_rooms).update(roomId, body: {
      'last_message': content.trim(),
      'last_message_at': DateTime.now().toUtc().toIso8601String(),
      'last_sender': me,
    });

    return ChatMessage.fromRecord(record, me);
  }

  Future<void> markMessagesAsRead(String roomId) async {
    final pb = await getPocketbaseInstance();
    final me = await _currentUserId(pb);
    final unread = await pb.collection(_messages).getFullList(
          filter: 'chat = "$roomId" && sender != "$me" && is_read = false',
        );
    for (final msg in unread) {
      await pb.collection(_messages).update(msg.id, body: {
        'is_read': true,
        'read_at': DateTime.now().toUtc().toIso8601String(),
      });
    }
  }

  Future<int> fetchUnreadCount(String roomId) async {
    final pb = await getPocketbaseInstance();
    final me = await _currentUserId(pb);
    final result = await pb.collection(_messages).getList(
          page: 1,
          perPage: 1,
          filter: 'chat = "$roomId" && sender != "$me" && is_read = false',
        );
    return result.totalItems;
  }

  (String, String) _sortedPair(String a, String b) {
    final list = [a, b]..sort();
    return (list[0], list[1]);
  }
}
