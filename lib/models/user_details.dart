class UserDetails {
  final String id;
  final String userId; // relation to users
  final String? level; // enum: Lower..., Intermediate..., etc.
  final List<String> playStyle; // multiple select: singles, doubles, mixed
  final String? avatar; // file name (PocketBase file field)
  final String? fullname;
  final String? gender; // enum: male, female (hoặc khác nếu bạn thêm)
  final DateTime? birthday;

  // Bạn có thể thêm phone, bio... nếu có trong collection

  UserDetails({
    required this.id,
    required this.userId,
    this.level,
    this.playStyle = const [],
    this.avatar,
    this.fullname,
    this.gender,
    this.birthday,
  });

  factory UserDetails.fromJson(Map<String, dynamic> json) {
    return UserDetails(
      id: json['id'] as String,
      userId: (json['user_id'] is Map)
          ? json['user_id']['id'] as String
          : (json['user_id'] as String),
      level: json['level'] as String?,
      playStyle: (json['play_style'] is List)
          ? (json['play_style'] as List).map((e) => e.toString()).toList()
          : <String>[],
      avatar: json['avatar'] as String?,
      fullname: json['fullname'] as String?,
      gender: json['gender'] as String?,
      birthday: (json['birthday'] != null && json['birthday'] != '')
          ? DateTime.tryParse(json['birthday'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'level': level,
      'play_style': playStyle,
      'avatar': avatar,
      'fullname': fullname,
      'gender': gender,
      'birthday': birthday?.toIso8601String(),
    };
  }
}
