import 'package:http/http.dart' as http;
import 'package:pocketbase/pocketbase.dart';

import '../models/chat_message.dart';
import '../models/chat_room.dart';
import '../services/pocketbase_client.dart';

class ChatService {
  static const chatsCollection = 'room_chats';
  static const messagesCollection = 'chat_messages';

  Future<String> ensureRoomWith(String otherUserId) async {
    final pb = await getPocketbaseInstance();
    final currentUserId = pb.authStore.record?.id;

    if (currentUserId == null) {
      throw Exception('Bạn chưa đăng nhập.');
    }

    final filter =
        "(user_a = '$currentUserId' && user_b = '$otherUserId') || (user_a = '$otherUserId' && user_b = '$currentUserId')";

    try {
      final existing =
          await pb.collection(chatsCollection).getFirstListItem(filter);
      return existing.id;
    } on ClientException catch (error) {
      if (error.statusCode != 404) rethrow;
    }

    final created = await pb.collection(chatsCollection).create(body: {
      'user_a': currentUserId,
      'user_b': otherUserId,
    });

    return created.id;
  }

  Future<List<ChatRoom>> fetchRooms() async {
    final pb = await getPocketbaseInstance();
    final currentUserId = pb.authStore.record?.id;

    if (currentUserId == null) {
      throw Exception('Bạn chưa đăng nhập.');
    }

    final result = await pb.collection(chatsCollection).getList(
          filter: "user_a = '$currentUserId' || user_b = '$currentUserId'",
          sort: '-last_message_at,-updated',
          expand:
              'user_a,user_b,last_sender,user_a.user_details_via_user_id,user_b.user_details_via_user_id',
        );

    return result.items
        .map((record) =>
            ChatRoom.fromRecord(record, currentUserId: currentUserId))
        .toList();
  }

  Future<List<ChatMessage>> fetchMessages(String chatId) async {
    final pb = await getPocketbaseInstance();
    final currentUserId = pb.authStore.record?.id;

    if (currentUserId == null) {
      throw Exception('Bạn chưa đăng nhập.');
    }

    final result = await pb.collection(messagesCollection).getList(
          filter: "chat = '$chatId'",
          sort: 'created',
          expand: 'sender',
          perPage: 200,
        );

    return result.items
        .map(
          (record) => ChatMessage.fromRecord(
            record,
            pb: pb,
            currentUserId: currentUserId,
          ),
        )
        .toList();
  }

  Future<ChatMessage> sendMessage({
    required String chatId,
    String content = '',
    http.MultipartFile? attachment,
  }) async {
    final pb = await getPocketbaseInstance();
    final currentUserId = pb.authStore.record?.id;

    if (currentUserId == null) {
      throw Exception('Bạn chưa đăng nhập.');
    }

    if (content.trim().isEmpty && attachment == null) {
      throw Exception('Vui lòng nhập tin nhắn hoặc chọn tệp đính kèm.');
    }

    final record = await pb.collection(messagesCollection).create(
      body: {
        'chat': chatId,
        'sender': currentUserId,
        'content': content.trim(),
        'is_read': false,
      },
      files: attachment != null
          ? <http.MultipartFile>[attachment]
          : <http.MultipartFile>[],
    );

    final lastMessageLabel = content.trim().isNotEmpty
        ? content.trim()
        : attachment != null
            ? '[Ảnh]'
            : '';

    await pb.collection(chatsCollection).update(chatId, body: {
      'last_message': lastMessageLabel,
      'last_message_at': DateTime.now().toIso8601String(),
      'last_sender': currentUserId,
    });

    return ChatMessage.fromRecord(
      record,
      pb: pb,
      currentUserId: currentUserId,
      authorName: 'You',
    );
  }

  Future<UnsubscribeFunc> subscribeRooms(
    String currentUserId,
    RecordSubscriptionFunc handler,
  ) async {
    final pb = await getPocketbaseInstance();
    return pb.collection(chatsCollection).subscribe(
          '*',
          handler,
          filter: "user_a = '$currentUserId' || user_b = '$currentUserId'",
          expand: 'user_a,user_b,last_sender',
        );
  }

  Future<UnsubscribeFunc> subscribeMessages(
    String chatId,
    RecordSubscriptionFunc handler,
  ) async {
    final pb = await getPocketbaseInstance();
    return pb.collection(messagesCollection).subscribe(
          '*',
          handler,
          filter: "chat = '$chatId'",
          expand: 'sender',
        );
  }
}
