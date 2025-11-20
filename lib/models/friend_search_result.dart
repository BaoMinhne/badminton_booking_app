import 'package:badminton_booking_app/models/user.dart';
import 'package:badminton_booking_app/models/user_details.dart';
import 'package:characters/characters.dart';

class FriendSearchResult {
  FriendSearchResult({
    required this.user,
    this.details,
  });

  final User user;
  final UserDetails? details;

  String get displayName {
    final fullname = details?.fullname?.trim();
    if (fullname != null && fullname.isNotEmpty) return fullname;

    if (user.username.isNotEmpty) return user.username;
    if (user.email.isNotEmpty) return user.email;
    return user.phone;
  }

  String get subtitle {
    if (user.email.isNotEmpty) return user.email;
    if (user.phone.isNotEmpty) return user.phone;
    return '';
  }

  String get initials {
    final source = displayName.trim();
    if (source.isEmpty) return '?';

    final parts = source.split(' ');
    if (parts.length == 1) {
      return parts.first.characters.take(2).toString().toUpperCase();
    }

    final first = parts.first.characters.take(1).toString();
    final last = parts.last.characters.take(1).toString();
    return '$first$last'.toUpperCase();
  }
}
