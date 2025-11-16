import 'package:characters/characters.dart';
import 'package:meta/meta.dart';
import 'package:pocketbase/pocketbase.dart';

@immutable
class UserSummary {
  const UserSummary({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    this.username,
    this.email,
  });

  final String id;
  final String displayName;
  final String? avatarUrl;
  final String? username;
  final String? email;

  factory UserSummary.fromRecord(RecordModel record, PocketBase pocketBase) {
    final avatarName = record.getStringValue('avatar');
    final avatarUrl = avatarName.isEmpty
        ? null
        : pocketBase.files.getUrl(record, avatarName).toString();

    final username = record.getStringValue('username');
    final email = record.getStringValue('email');
    final displayName = username.isNotEmpty
        ? username
        : (email.isNotEmpty ? email : record.id);

    return UserSummary(
      id: record.id,
      displayName: displayName,
      avatarUrl: avatarUrl,
      username: username.isNotEmpty ? username : null,
      email: email.isNotEmpty ? email : null,
    );
  }

  String get initials {
    if (displayName.trim().isEmpty) {
      return '#';
    }
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.characters.first.toUpperCase();
    }
    final buffer = StringBuffer();
    for (final part in parts.take(2)) {
      if (part.isNotEmpty) {
        buffer.write(part.characters.first.toUpperCase());
      }
    }
    final result = buffer.toString();
    return result.isEmpty ? displayName.characters.first.toUpperCase() : result;
  }
}
