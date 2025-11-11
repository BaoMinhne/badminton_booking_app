import 'package:pocketbase/pocketbase.dart';

class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.imageUrls,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
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

    final authorRecord = _resolveExpandedRecord(record.expand?['author']);
    final authorData = authorRecord?.data;
    final displayName = _sanitizeName(
      (authorData?['username'] as String?) ??
          (authorData?['email'] as String?) ??
          'Người dùng',
    );

    return CommunityPost(
      id: record.id,
      authorId: (data['author'] as String?) ?? authorRecord?.id ?? '',
      authorName: displayName,
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
  final String content;
  final List<String> imageUrls;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get hasImages => imageUrls.isNotEmpty;
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

String _sanitizeName(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return 'Người dùng';
  }
  return trimmed;
}
