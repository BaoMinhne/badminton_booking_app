import 'package:badminton_booking_app/models/chat_contact.dart';
import 'package:badminton_booking_app/models/user.dart';
import 'package:badminton_booking_app/models/user_details.dart';

class FriendCandidate {
  const FriendCandidate({
    required this.user,
    this.details,
  });

  final User user;
  final UserDetails? details;

  String get displayName {
    final fullName = details?.fullname?.trim();
    if (fullName != null && fullName.isNotEmpty) {
      return fullName;
    }
    if (user.username.trim().isNotEmpty) {
      return user.username.trim();
    }
    if (user.email.trim().isNotEmpty) {
      return user.email.trim();
    }
    if (user.phone.trim().isNotEmpty) {
      return user.phone.trim();
    }
    return 'Người dùng';
  }

  String? get statusMessage {
    final parts = <String>[];
    if (user.username.trim().isNotEmpty) {
      parts.add('@${user.username.trim()}');
    }
    if (user.email.trim().isNotEmpty) {
      parts.add(user.email.trim());
    }
    if (user.phone.trim().isNotEmpty) {
      parts.add(user.phone.trim());
    }
    if (details?.level != null && details!.level!.trim().isNotEmpty) {
      parts.add(details!.level!.trim());
    }
    if (parts.isEmpty) {
      return null;
    }
    return parts.join(' • ');
  }

  String get avatarText {
    final normalized = displayName.trim();
    if (normalized.isEmpty) {
      return '??';
    }
    final segments = normalized
        .split(RegExp(r'\s+'))
        .where((segment) => segment.isNotEmpty)
        .toList(growable: false);
    if (segments.isEmpty) {
      return '??';
    }
    if (segments.length == 1) {
      final value = segments.first;
      final length = value.length >= 2 ? 2 : 1;
      return value.substring(0, length).toUpperCase();
    }
    return (_firstCharacter(segments.first) + _firstCharacter(segments.last))
        .toUpperCase();
  }

  String? get avatarUrl => details?.avatarUrl;

  ChatContact toChatContact() {
    return ChatContact(
      id: user.id,
      name: displayName,
      avatarText: avatarText,
      avatarUrl: avatarUrl,
      statusMessage: statusMessage,
    );
  }

  String _firstCharacter(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '?';
    }
    final firstCodePoint = trimmed.runes.first;
    return String.fromCharCode(firstCodePoint);
  }
}
