import 'package:pocketbase/pocketbase.dart';

class RecruitmentPost {
  RecruitmentPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.createdAt,
    required this.isActive,
    this.authorAvatarUrl,
    this.updatedAt,
    this.courtId,
    this.courtName,
    this.eventTime,
    this.targetMemberCount,
    this.skillLevel,
    this.playStyle,
    this.locationNote,
    this.expiresAt,
    this.hasCurrentUserJoined = false,
    List<RecruitmentApplicant>? applicants,
  }) : applicants = applicants ?? const [];

  factory RecruitmentPost.fromRecord(
    RecordModel record,
    PocketBase pocketBase, {
    String? currentUserId,
  }) {
    final data = record.data;
    final expand = record.expand ?? {};

    final authorRecord = _resolveExpandedRecord(expand['author']);
    final rawAuthorName =
        (authorRecord?.data['username'] as String?)?.trim() ?? '';
    final avatarName = _extractFirstFileName(authorRecord?.data['avatar']);
    final avatarUrl = (authorRecord != null && avatarName != null)
        ? pocketBase.files.getUrl(authorRecord, avatarName).toString()
        : null;

    final courtRecord = _resolveExpandedRecord(expand['court']);
    final courtName =
        (courtRecord?.data['name'] as String?)?.trim().isNotEmpty == true
            ? (courtRecord!.data['name'] as String).trim()
            : null;

    final applicantsRecords =
        _resolveExpandedRecords(expand['recruitment_applicants(recruitment)']);
    final applicants = applicantsRecords
        .map((record) => RecruitmentApplicant.fromRecord(record))
        .toList(growable: false);

    final hasJoined = currentUserId != null &&
        applicants.any((applicant) => applicant.userId == currentUserId);

    final targetMembers = _parseInt(data['need_members']);

    return RecruitmentPost(
      id: record.id,
      authorId: (data['author'] as String?)?.trim() ?? '',
      authorName: rawAuthorName.isEmpty ? 'Người chơi' : rawAuthorName,
      authorAvatarUrl: avatarUrl,
      content: (data['content'] as String?)?.trim() ?? '',
      courtId: (data['court'] as String?)?.trim(),
      courtName: courtName,
      eventTime: _parseDate(data['event_time']),
      targetMemberCount: targetMembers > 0 ? targetMembers : null,
      skillLevel: (data['skill_level'] as String?)?.trim(),
      playStyle: (data['play_style'] as String?)?.trim(),
      locationNote: (data['location_note'] as String?)?.trim(),
      createdAt: _parseDate(data['created']) ?? DateTime.now().toUtc(),
      updatedAt: _parseDate(data['updated']),
      expiresAt: _parseDate(data['expires_at']),
      isActive: _parseBool(data['is_active']),
      applicants: applicants,
      hasCurrentUserJoined: hasJoined,
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
  final String? courtId;
  final String? courtName;
  final DateTime? eventTime;
  final int? targetMemberCount;
  final String? skillLevel;
  final String? playStyle;
  final String? locationNote;
  final DateTime? expiresAt;
  final bool hasCurrentUserJoined;
  final List<RecruitmentApplicant> applicants;

  int get applicantCount => applicants.length;

  int get joinedMemberCount => applicantCount + 1; // +1 cho chủ bài đăng

  RecruitmentPost copyWith({
    List<RecruitmentApplicant>? applicants,
    bool? hasCurrentUserJoined,
  }) {
    return RecruitmentPost(
      id: id,
      authorId: authorId,
      authorName: authorName,
      authorAvatarUrl: authorAvatarUrl,
      content: content,
      createdAt: createdAt,
      isActive: isActive,
      updatedAt: updatedAt,
      courtId: courtId,
      courtName: courtName,
      eventTime: eventTime,
      targetMemberCount: targetMemberCount,
      skillLevel: skillLevel,
      playStyle: playStyle,
      locationNote: locationNote,
      expiresAt: expiresAt,
      applicants: applicants ?? this.applicants,
      hasCurrentUserJoined: hasCurrentUserJoined ?? this.hasCurrentUserJoined,
    );
  }
}

class RecruitmentApplicant {
  const RecruitmentApplicant({
    required this.id,
    required this.recruitmentId,
    required this.userId,
    required this.createdAt,
  });

  factory RecruitmentApplicant.fromRecord(RecordModel record) {
    final data = record.data;
    return RecruitmentApplicant(
      id: record.id,
      recruitmentId: (data['recruitment'] as String?)?.trim() ?? '',
      userId: (data['user'] as String?)?.trim() ?? '',
      createdAt: _parseDate(data['created']) ?? DateTime.now().toUtc(),
    );
  }

  final String id;
  final String recruitmentId;
  final String userId;
  final DateTime createdAt;
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

List<RecordModel> _resolveExpandedRecords(dynamic expanded) {
  if (expanded is RecordModel) {
    return [expanded];
  }

  if (expanded is List) {
    return expanded.whereType<RecordModel>().toList(growable: false);
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

int _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
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
