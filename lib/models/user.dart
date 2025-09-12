class User {
  final String id;
  final String username;
  final String email;
  final String phone;
  final String? name;
  final String? avatar;
  final String? role;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.phone,
    this.name,
    this.avatar,
    this.role,
  });

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? phone,
    String? name,
    String? avatar,
    String? role,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      name: json['name'] ?? '',
      avatar: json['avatar'] ?? '',
      role: json['role'] ?? '',
    );
  }
}
