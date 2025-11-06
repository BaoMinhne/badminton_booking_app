import 'package:pocketbase/pocketbase.dart';

class Post {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final String? content;
  final List<String> imageUrls;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Post({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.imageUrls,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.authorAvatarUrl,
  });

  factory Post.fromRecord(PocketBase client, RecordModel record) {
    final data = record.toJson();
    final authorInfo = _extractAuthor(client, record);
    final rawImages = data['images'];

    final imageUrls = <String>[];
    if (rawImages is String && rawImages.isNotEmpty) {
      imageUrls.add(client.files.getUrl(record, rawImages).toString());
    } else if (rawImages is List) {
      for (final item in rawImages) {
        if (item is String && item.isNotEmpty) {
          imageUrls.add(client.files.getUrl(record, item).toString());
        }
      }
    }

    return Post(
      id: data['id'] as String? ?? '',
      authorId: data['author'] as String? ?? authorInfo?.id ?? '',
      authorName: authorInfo?.username ?? 'Ẩn danh',
      authorAvatarUrl: authorInfo?.avatarUrl,
      content: (data['content'] as String?)?.trim(),
      imageUrls: imageUrls,
      isActive: _parseBool(data['is_active']),
      createdAt: _parseDate(data['created']) ?? DateTime.now(),
      updatedAt: _parseDate(data['updated']) ?? DateTime.now(),
    );
  }

  static _AuthorInfo? _extractAuthor(PocketBase client, RecordModel record) {
    final expand = record.expand;
    if (expand == null || expand.isEmpty) {
      return null;
    }

    final expandedAuthor = expand['author'];

    if (expandedAuthor is RecordModel) {
      return _AuthorInfo.fromRecord(client, expandedAuthor);
    }

    if (expandedAuthor is List) {
      for (final item in expandedAuthor) {
        if (item is RecordModel) {
          return _AuthorInfo.fromRecord(client, item);
        }
      }
    }

    return null;
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true') return true;
      if (lower == 'false') return false;
      final number = num.tryParse(value);
      if (number != null) return number != 0;
    }
    return false;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}

class _AuthorInfo {
  final String id;
  final String username;
  final String? avatarUrl;

  _AuthorInfo({
    required this.id,
    required this.username,
    this.avatarUrl,
  });

  factory _AuthorInfo.fromRecord(PocketBase client, RecordModel record) {
    final data = record.toJson();
    final avatarField = data['avatar'];
    String? avatarUrl;

    if (avatarField is String && avatarField.isNotEmpty) {
      avatarUrl = client.files.getUrl(record, avatarField).toString();
    }

    return _AuthorInfo(
      id: data['id'] as String? ?? '',
      username: data['username'] as String? ?? 'Người dùng',
      avatarUrl: avatarUrl,
    );
  }
}
