import 'package:badminton_booking_app/utils/recruitment_dictionary.dart';
import 'package:pocketbase/pocketbase.dart';

class RecruitmentPost {
  const RecruitmentPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.description,
    required this.requiredPlayers,
    required this.joinedPlayers,
    required this.skillLevel,
    required this.playStyle,
    required this.createdAt,
    required this.eventTime,
    required this.courtName,
    required this.isJoined,
    required this.isOwner,
    required this.locationNote,
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
    final authorName = _sanitizeName(
      (authorData?['username'] as String?) ??
          (authorData?['email'] as String?) ??
          'Người chơi',
    );

    final courtRecord = _resolveExpandedRecord(record.expand?['court']);
    final courtData = courtRecord?.data;
    final courtName = _sanitizeName(courtData?['name'] as String?);

    final applicantUserIds = applicants
        .map((rec) => (rec.data['user'] as String?) ?? rec.getStringValue('user'))
        .where((id) => id != null && id.isNotEmpty)
        .cast<String>()
        .toList();

    final joinedCount = applicantUserIds.length + 1; // tính cả chủ bài
    final hasJoined = applicantUserIds.contains(currentUserId);

    return RecruitmentPost(
      id: record.id,
      authorId: authorId,
      authorName: authorName,
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
      isJoined: hasJoined || authorId == currentUserId,
      isOwner: authorId == currentUserId,
      locationNote: (data['location_note'] as String?)?.trim(),
    );
  }

  final String id;
  final String authorId;
  final String authorName;
  final String description;
  final int requiredPlayers;
  final int joinedPlayers;
  final String skillLevel;
  final String playStyle;
  final DateTime createdAt;
  final DateTime? eventTime;
  final String? courtName;
  final bool isJoined;
  final bool isOwner;
  final String? locationNote;

  RecruitmentPost copyWith({
    int? joinedPlayers,
    bool? isJoined,
  }) {
    return RecruitmentPost(
      id: id,
      authorId: authorId,
      authorName: authorName,
      description: description,
      requiredPlayers: requiredPlayers,
      joinedPlayers: joinedPlayers ?? this.joinedPlayers,
      skillLevel: skillLevel,
      playStyle: playStyle,
      createdAt: createdAt,
      eventTime: eventTime,
      courtName: courtName,
      isJoined: isJoined ?? this.isJoined,
      isOwner: isOwner,
      locationNote: locationNote,
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
