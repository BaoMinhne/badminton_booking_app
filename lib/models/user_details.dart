class UserDetails {
  final String id;
  final String userId; // relation to users
  final String? level; // enum: Lower..., Intermediate..., etc.
  final int levelNumeric; // required 1-5
  final List<String> matchTypes; // multiple select: singles, doubles, mixed
  final List<String> playStyleTags; // multiple select: attack, defense, ...
  final String? avatar;
  final String? avatarUrl; // file name (PocketBase file field)
  final String? fullname;
  final String? gender; // enum: male, female (hoặc khác nếu bạn thêm)
  final DateTime? birthday;
  final String? preferredRoleDoubles; // enum: front, back, flexible
  final String? intensity; // enum: casual, semi_competitive, competitive
  final int? experienceYears;
  final int? playsPerWeek;
  final String? homeCourtId; // relation to courts

  // Bạn có thể thêm phone, bio... nếu có trong collection

  UserDetails({
    required this.id,
    required this.userId,
    required this.levelNumeric,
    this.level,
    this.matchTypes = const [],
    this.playStyleTags = const [],
    this.avatar,
    this.avatarUrl,
    this.fullname,
    this.gender,
    this.birthday,
    this.preferredRoleDoubles,
    this.intensity,
    this.experienceYears,
    this.playsPerWeek,
    this.homeCourtId,
  });

  factory UserDetails.fromJson(Map<String, dynamic> json, {String? avatarUrl}) {
    return UserDetails(
      id: json['id'] as String,
      userId: (json['user_id'] is Map)
          ? json['user_id']['id'] as String
          : (json['user_id'] as String),
      level: json['level'] as String?,
      levelNumeric: (json['level_numeric'] as num?)?.toInt() ?? 3,
      matchTypes: (json['match_types'] is List)
          ? (json['match_types'] as List).map((e) => e.toString()).toList()
          : (json['play_style'] is List)
              ? (json['play_style'] as List)
                  .map((e) => e.toString())
                  .toList(growable: false)
              : <String>[],
      playStyleTags: (json['play_style_tags'] is List)
          ? (json['play_style_tags'] as List)
              .map((e) => e.toString())
              .toList()
          : <String>[],
      avatar: json['avatar'] as String?,
      avatarUrl: avatarUrl,
      fullname: json['fullname'] as String?,
      gender: json['gender'] as String?,
      birthday: (json['birthday'] != null && json['birthday'] != '')
          ? DateTime.tryParse(json['birthday'])
          : null,
      preferredRoleDoubles: json['preferred_role_doubles'] as String?,
      intensity: json['intensity'] as String?,
      experienceYears: (json['experience_years'] as num?)?.toInt(),
      playsPerWeek: (json['plays_per_week'] as num?)?.toInt(),
      homeCourtId: json['home_court'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'level': level,
      'level_numeric': levelNumeric,
      'match_types': matchTypes,
      'play_style_tags': playStyleTags,
      'avatar': avatar,
      'fullname': fullname,
      'gender': gender,
      'birthday': birthday?.toIso8601String(),
      'preferred_role_doubles': preferredRoleDoubles,
      'intensity': intensity,
      'experience_years': experienceYears,
      'plays_per_week': playsPerWeek,
      'home_court': homeCourtId,
    };
  }

  UserDetails copyWith({
    int? levelNumeric,
    String? level,
    List<String>? matchTypes,
    List<String>? playStyleTags,
    String? avatar,
    String? avatarUrl,
    String? fullname,
    String? gender,
    DateTime? birthday,
    String? preferredRoleDoubles,
    String? intensity,
    int? experienceYears,
    int? playsPerWeek,
    String? homeCourtId,
  }) {
    return UserDetails(
      id: id,
      userId: userId,
      levelNumeric: levelNumeric ?? this.levelNumeric,
      level: level ?? this.level,
      matchTypes: matchTypes ?? List<String>.from(this.matchTypes),
      playStyleTags:
          playStyleTags ?? List<String>.from(this.playStyleTags),
      avatar: avatar ?? this.avatar,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      fullname: fullname ?? this.fullname,
      gender: gender ?? this.gender,
      birthday: birthday ?? this.birthday,
      preferredRoleDoubles:
          preferredRoleDoubles ?? this.preferredRoleDoubles,
      intensity: intensity ?? this.intensity,
      experienceYears: experienceYears ?? this.experienceYears,
      playsPerWeek: playsPerWeek ?? this.playsPerWeek,
      homeCourtId: homeCourtId ?? this.homeCourtId,
    );
  }

  bool get isComplete {
    return (fullname?.trim().isNotEmpty ?? false) &&
        (level?.trim().isNotEmpty ?? false) &&
        levelNumeric > 0 &&
        matchTypes.isNotEmpty &&
        playStyleTags.isNotEmpty &&
        (preferredRoleDoubles?.trim().isNotEmpty ?? false) &&
        (intensity?.trim().isNotEmpty ?? false) &&
        experienceYears != null &&
        playsPerWeek != null &&
        (gender?.trim().isNotEmpty ?? false) &&
        birthday != null;
  }
}
