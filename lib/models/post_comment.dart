import 'package:pocketbase/pocketbase.dart';

import '../utils/pocketbase_utils.dart';

class PostComment {
  const PostComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.authorAvatarUrl,
    required this.content,
    required this.createdAt,
  });

  factory PostComment.fromRecord(RecordModel record, PocketBase pocketBase) {
    final data = record.data;
    final authorRecord = resolveExpandedRecord(record.expand?['author']);
    final authorData = authorRecord?.data;

    return PostComment(
      id: record.id,
      postId: (data['post'] as String?) ?? '',
      authorId: (data['author'] as String?) ?? authorRecord?.id ?? '',
      authorName: sanitizeDisplayName(
        (authorData?['username'] as String?) ??
            (authorData?['email'] as String?) ??
            'Người dùng',
      ),
      authorAvatarUrl: resolveFileUrl(
        pocketBase,
        authorRecord,
        authorData?['avatar'],
      ),
      content: (data['content'] as String?)?.trim() ?? '',
      createdAt: DateTime.parse(data['created'] as String),
    );
  }

  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final String content;
  final DateTime createdAt;
}
