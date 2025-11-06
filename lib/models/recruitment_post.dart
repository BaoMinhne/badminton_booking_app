import 'package:pocketbase/pocketbase.dart';

class RecruitmentPost {
  final String id;
  final String authorId;
  final String authorName;
  final String? courtId;
  final String? courtName;
  final String? content;
  final DateTime createdAt;
  final DateTime? eventTime;
  final DateTime? expiresAt;
  final int requiredMembers;
  final int joinedMembers;
  final String? skillLevel;
  final String? playStyle;
  final String? locationNote;
  final bool isActive;

  const RecruitmentPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.courtId,
    required this.courtName,
    required this.content,
    required this.createdAt,
    required this.eventTime,
    required this.expiresAt,
    required this.requiredMembers,
    required this.joinedMembers,
    required this.skillLevel,
    required this.playStyle,
    required this.locationNote,
    required this.isActive,
  });

  RecruitmentPost copyWith({
    int? joinedMembers,
  }) {
    return RecruitmentPost(
      id: id,
      authorId: authorId,
      authorName: authorName,
      courtId: courtId,
      courtName: courtName,
      content: content,
      createdAt: createdAt,
      eventTime: eventTime,
      expiresAt: expiresAt,
      requiredMembers: requiredMembers,
      joinedMembers: joinedMembers ?? this.joinedMembers,
      skillLevel: skillLevel,
      playStyle: playStyle,
      locationNote: locationNote,
      isActive: isActive,
    );
  }

  factory RecruitmentPost.fromRecord(
    RecordModel record, {
    int joinedCount = 0,
  }) {
    final data = record.toJson();
    final authorInfo = _extractAuthor(record);
    final courtInfo = _extractCourt(record);

    return RecruitmentPost(
      id: data['id'] as String? ?? '',
      authorId: data['author'] as String? ?? authorInfo?.id ?? '',
      authorName: authorInfo?.username ?? 'Ẩn danh',
      courtId: data['court'] as String? ?? courtInfo?.id,
      courtName: courtInfo?.name,
      content: (data['content'] as String?)?.trim(),
      createdAt: _parseDate(data['created']) ?? DateTime.now(),
      eventTime: _parseDate(data['event_time']),
      expiresAt: _parseDate(data['expires_at']),
      requiredMembers: _parseInt(data['need_members']),
      joinedMembers: joinedCount,
      skillLevel: (data['skill_level'] as String?)?.trim(),
      playStyle: (data['play_style'] as String?)?.trim(),
      locationNote: (data['location_note'] as String?)?.trim(),
      isActive: _parseBool(data['is_active']),
    );
  }

  static _AuthorInfo? _extractAuthor(RecordModel record) {
    final expand = record.expand;
    if (expand == null || expand.isEmpty) return null;

    final authorRecord = _firstRecord(expand['author']);
    if (authorRecord == null) {
      return null;
    }

    return _AuthorInfo.fromRecord(authorRecord);
  }

  static _CourtInfo? _extractCourt(RecordModel record) {
    final expand = record.expand;
    if (expand == null || expand.isEmpty) return null;

    final courtRecord = _firstRecord(expand['court']);
    if (courtRecord == null) {
      return null;
    }

    return _CourtInfo.fromRecord(courtRecord);
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true') return true;
      if (lower == 'false') return false;
      final parsed = num.tryParse(value);
      if (parsed != null) return parsed != 0;
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

RecordModel? _firstRecord(dynamic value) {
  if (value is RecordModel) {
    return value;
  }

  if (value is List) {
    for (final dynamic item in value) {
      if (item is RecordModel) {
        return item;
      }
    }
  }

  return null;
}

class _AuthorInfo {
  final String id;
  final String username;

  _AuthorInfo({
    required this.id,
    required this.username,
  });

  factory _AuthorInfo.fromRecord(RecordModel record) {
    final data = record.toJson();
    return _AuthorInfo(
      id: data['id'] as String? ?? '',
      username: data['username'] as String? ?? 'Người chơi',
    );
  }
}

class _CourtInfo {
  final String id;
  final String name;

  _CourtInfo({
    required this.id,
    required this.name,
  });

  factory _CourtInfo.fromRecord(RecordModel record) {
    final data = record.toJson();
    return _CourtInfo(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? 'Sân cầu lông',
    );
  }
}
