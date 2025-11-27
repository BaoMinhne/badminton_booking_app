import 'package:badminton_booking_app/utils/recruitment_dictionary.dart';
import 'package:pocketbase/pocketbase.dart';

import '../utils/pocketbase_utils.dart';

class RecruitmentPost {
  const RecruitmentPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorAvatarUrl,
    required this.description,
    required this.requiredPlayers,
    required this.joinedPlayers,
    required this.skillLevel,
    required this.playStyle,
    required this.createdAt,
    required this.eventTime,
    required this.courtName,
    required this.isJoined,
    this.currentUserStatus,
    required this.isOwner,
    required this.locationNote,
    required this.isActive,
    required this.expiresAt,
    required this.hasCourt,
  });

  factory RecruitmentPost.fromRecord({
    required RecordModel record,
    required PocketBase pocketBase,
    required String? currentUserId,
    List<RecordModel> applicants = const [],
  }) {
    final data = record.data;

    final authorRecord = _resolveExpandedRecord(record.expand?['author']);
    final authorData = authorRecord?.data;
    final authorId = (data['author'] as String?) ?? authorRecord?.id ?? '';
    final loggedInUserId = currentUserId ?? pocketBase.authStore.record?.id;
    final isOwner = authorId == loggedInUserId;
    final authorName = isOwner
        ? 'Bạn'
        : _sanitizeName(
              (authorData?['username'] as String?) ??
                  (authorData?['email'] as String?),
              // Bỏ fallback 'Người chơi' ở trong này
            ) ??
            'Người chơi';
    final authorAvatarUrl = resolveFileUrl(
      pocketBase,
      authorRecord,
      authorData?['avatar'],
    );

    final courtRecord = _resolveExpandedRecord(record.expand?['court']);
    final courtData = courtRecord?.data;
    final courtName = _sanitizeName(courtData?['name'] as String?);
    final courtId = (data['court'] as String?) ?? courtRecord?.id;

    final applicantUserIds = <String>[];
    String? currentUserStatus;

    for (final rec in applicants) {
      final userId =
          (rec.data['user'] as String?) ?? rec.getStringValue('user') ?? '';
      if (userId.isEmpty) continue;

      applicantUserIds.add(userId);

      // Nếu đây là request của chính user đang đăng nhập
      if (loggedInUserId != null &&
          loggedInUserId.isNotEmpty &&
          userId == loggedInUserId &&
          currentUserStatus == null) {
        currentUserStatus = (rec.data['status'] as String?) ?? 'pending';
      }
    }

    final acceptedApplicants = applicants.where((rec) {
      final status = (rec.data['status'] as String?) ?? 'pending';
      return status == 'accepted';
    }).length;

    final joinedCount = acceptedApplicants + 1; // tính cả chủ bài

    // Chỉ coi là "đã tham gia" khi đã được accepted hoặc là chủ bài
    final hasJoined = currentUserStatus == 'accepted' || isOwner;

    final expiresAt = _tryParseDateTime(data['expires_at']);
    final bool isActiveFlag = (data['is_active'] as bool?) ?? true;
    final now = DateTime.now();

// expires_at <= now coi là đã hết hạn
    final bool isExpired = expiresAt != null && !expiresAt.isAfter(now);

// chỉ "đang tuyển" khi DB còn active và chưa hết hạn
    final bool isActive = isActiveFlag && !isExpired;

    return RecruitmentPost(
      id: record.id,
      authorId: authorId,
      authorName: authorName,
      authorAvatarUrl: authorAvatarUrl,
      description: (data['content'] as String?)?.trim() ?? '',
      requiredPlayers: (data['need_members'] as int?) ?? 0,
      joinedPlayers: joinedCount,
      skillLevel:
          RecruitmentDictionary.skillLabelFromValue(data['skill_level']),
      playStyle: RecruitmentDictionary.playStyleLabelFromValue(
        data['play_style'] as String?,
      ),
      createdAt: DateTime.parse(data['created'] as String),
      eventTime: _tryParseDateTime(data['event_time']),
      courtName: courtName,
      isJoined: hasJoined || authorId == loggedInUserId,
      currentUserStatus: currentUserStatus,
      isOwner: isOwner,
      locationNote: (data['location_note'] as String?)?.trim(),
      isActive: isActive,
      expiresAt: expiresAt,
      hasCourt: courtId != null && courtId.isNotEmpty,
    );
  }

  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final String description;
  final int requiredPlayers;
  final int joinedPlayers;
  final String skillLevel;
  final String playStyle;
  final DateTime createdAt;
  final DateTime? eventTime;
  final String? courtName;
  final bool isJoined;
  final String? currentUserStatus;
  final bool isOwner;
  final String? locationNote;
  final bool isActive;
  final DateTime? expiresAt;
  final bool hasCourt;

  RecruitmentPost copyWith({
    int? joinedPlayers,
    bool? isJoined,
    String? authorAvatarUrl,
    bool? isActive,
    DateTime? expiresAt,
    String? currentUserStatus,
  }) {
    return RecruitmentPost(
      id: id,
      authorId: authorId,
      authorName: authorName,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      description: description,
      requiredPlayers: requiredPlayers,
      joinedPlayers: joinedPlayers ?? this.joinedPlayers,
      skillLevel: skillLevel,
      playStyle: playStyle,
      createdAt: createdAt,
      eventTime: eventTime,
      courtName: courtName,
      isJoined: isJoined ?? this.isJoined,
      currentUserStatus: currentUserStatus ?? this.currentUserStatus,
      isOwner: isOwner,
      locationNote: locationNote,
      isActive: isActive ?? this.isActive,
      expiresAt: expiresAt ?? this.expiresAt,
      hasCourt: hasCourt,
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

String? _sanitizeName(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

DateTime? _tryParseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value.toLocal();
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value)?.toLocal();
  }
  return null;
}
