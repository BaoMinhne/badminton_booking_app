import 'package:pocketbase/pocketbase.dart';

import '../utils/pocketbase_utils.dart';

class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorAvatarUrl,
    required this.content,
    required this.imageUrls,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.likesCount = 0,
    this.isLiked = false,
    this.likeRecordId,
    this.commentsCount = 0,
  });

  factory CommunityPost.fromRecord(RecordModel record, PocketBase pocketBase) {
    final data = record.data;
    final rawImages = data['images'];

    final imageUrls = <String>[];
    final fileNames = _normalizeFileList(rawImages);
    for (final fileName in fileNames) {
      final url = pocketBase.files.getUrl(record, fileName).toString();
      imageUrls.add(url);
    }

    final authorRecord = resolveExpandedRecord(record.expand?['author']);
    final authorData = authorRecord?.data;
    final authorId = (data['author'] as String?) ?? authorRecord?.id ?? '';
    final isOwner =
        authorId.isNotEmpty && authorId == pocketBase.authStore.record?.id;
    final displayName = isOwner
        ? 'You'
        : sanitizeDisplayName(
            (authorData?['username'] as String?) ??
                (authorData?['email'] as String?) ??
                'Người dùng',
          );
    final avatarUrl = resolveFileUrl(
      pocketBase,
      authorRecord,
      authorData?['avatar'],
    );

    return CommunityPost(
      id: record.id,
      authorId: authorId,
      authorName: displayName,
      authorAvatarUrl: avatarUrl,
      content: (data['content'] as String?)?.trim() ?? '',
      imageUrls: imageUrls,
      isActive: data['is_active'] == true,
      createdAt: DateTime.parse(data['created'] as String),
      updatedAt: DateTime.parse(data['updated'] as String),
    );
  }

  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final String content;
  final List<String> imageUrls;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int likesCount;
  final bool isLiked;
  final String? likeRecordId;
  final int commentsCount;

  bool get hasImages => imageUrls.isNotEmpty;

  CommunityPost copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorAvatarUrl,
    String? content,
    List<String>? imageUrls,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? likesCount,
    bool? isLiked,
    Object? likeRecordId = _unset,
    int? commentsCount,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      content: content ?? this.content,
      imageUrls: imageUrls ?? this.imageUrls,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
      likeRecordId: likeRecordId == _unset
          ? this.likeRecordId
          : likeRecordId as String?,
      commentsCount: commentsCount ?? this.commentsCount,
    );
  }
}

List<String> _normalizeFileList(dynamic value) {
  if (value is String && value.isNotEmpty) {
    return [value];
  }
  if (value is List) {
    return value
        .whereType<String>()
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toList();
  }
  return const [];
}

const Object _unset = Object();
