import 'package:pocketbase/pocketbase.dart';

class CommunityPost {
  CommunityPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.createdAt,
    required this.isActive,
    this.authorAvatarUrl,
    this.updatedAt,
    List<String>? imageUrls,
  }) : imageUrls = imageUrls ?? const [];

  factory CommunityPost.fromRecord(
    RecordModel record,
    PocketBase pocketBase,
  ) {
    final data = record.data;
    final expand = record.expand ?? {};

    final authorRecord = _resolveExpandedRecord(expand['author']);
    final rawAuthorName =
        (authorRecord?.data['username'] as String?)?.trim() ?? '';
    final avatarField = authorRecord?.data['avatar'];
    final avatarName = _extractFirstFileName(avatarField);
    final avatarUrl = (authorRecord != null && avatarName != null)
        ? pocketBase.files.getUrl(authorRecord, avatarName).toString()
        : null;

    final rawImages = data['images'];
    final imageNames = _extractFileList(rawImages);
    final imageUrls = imageNames
        .map((name) => pocketBase.files.getUrl(record, name).toString())
        .toList(growable: false);

    return CommunityPost(
      id: record.id,
      authorId: (data['author'] as String?)?.trim() ?? '',
      authorName: rawAuthorName.isEmpty ? 'Người chơi' : rawAuthorName,
      authorAvatarUrl: avatarUrl,
      content: (data['content'] as String?)?.trim() ?? '',
      createdAt: _parseDate(data['created']) ?? DateTime.now().toUtc(),
      updatedAt: _parseDate(data['updated'])?.toUtc(),
      isActive: _parseBool(data['is_active']),
      imageUrls: imageUrls,
    );
  }

  final String id;
  final String authorId;
  final String authorName;
  final String content;
  final DateTime createdAt;
  final bool isActive;
  final String? authorAvatarUrl;
  final DateTime? updatedAt;
  final List<String> imageUrls;

  bool get hasImages => imageUrls.isNotEmpty;

  CommunityPost copyWith({
    String? content,
    DateTime? updatedAt,
    List<String>? imageUrls,
  }) {
    return CommunityPost(
      id: id,
      authorId: authorId,
      authorName: authorName,
      authorAvatarUrl: authorAvatarUrl,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive,
      imageUrls: imageUrls ?? this.imageUrls,
    );
  }
}

RecordModel? _resolveExpandedRecord(dynamic expanded) {
  if (expanded is RecordModel) {
    return expanded;
  }

  if (expanded is List) {
    for (final item in expanded) {
      if (item is RecordModel) {
        return item;
      }
    }
  }

  return null;
}

List<String> _extractFileList(dynamic raw) {
  if (raw is String) {
    return raw.isEmpty ? const [] : <String>[raw];
  }

  if (raw is List) {
    return raw
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  return const [];
}

String? _extractFirstFileName(dynamic value) {
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }

  if (value is List && value.isNotEmpty) {
    final first = value.first;
    if (first is String && first.trim().isNotEmpty) {
      return first.trim();
    }
  }

  return null;
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value.toUtc();
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value)?.toUtc();
  }
  return null;
}

bool _parseBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final lower = value.toLowerCase();
    if (lower == 'true') return true;
    if (lower == 'false') return false;
    final numeric = num.tryParse(value);
    if (numeric != null) {
      return numeric != 0;
    }
  }
  return false;
}
