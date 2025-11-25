import '../utils/pocketbase_utils.dart';
import '../utils/recruitment_dictionary.dart';

class RecruitmentApplicant {
  const RecruitmentApplicant({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.status,
    required this.createdAt,
    this.avatarUrl,
    this.level,
    this.playStyles = const [],
  });

  factory RecruitmentApplicant.fromJson(Map<String, dynamic> json) {
    return RecruitmentApplicant(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      displayName: sanitizeDisplayName(json['display_name'] as String?),
      status: json['status'] as String? ?? 'pending',
      avatarUrl: json['avatar_url'] as String?,
      level: RecruitmentDictionary.skillLabelFromValue(json['level']),
      playStyles: (json['play_styles'] as List?)
              ?.map((e) => RecruitmentDictionary.playStyleLabelFromValue(e))
              .whereType<String>()
              .toList(growable: false) ??
          const [],
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String id;
  final String userId;
  final String displayName;
  final String status;
  final DateTime createdAt;
  final String? avatarUrl;
  final String? level;
  final List<String> playStyles;

  RecruitmentApplicant copyWith({
    String? status,
  }) {
    return RecruitmentApplicant(
      id: id,
      userId: userId,
      displayName: displayName,
      status: status ?? this.status,
      createdAt: createdAt,
      avatarUrl: avatarUrl,
      level: level,
      playStyles: playStyles,
    );
  }
}
