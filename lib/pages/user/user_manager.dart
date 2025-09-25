import 'dart:io';

import 'package:badminton_booking_app/models/user.dart';
import 'package:badminton_booking_app/services/user_service.dart';
import 'package:flutter/foundation.dart';

import 'package:badminton_booking_app/models/user_details.dart';

class UserManager with ChangeNotifier {
  late final UserDetailsService _userService;

  UserManager() {
    _userService = UserDetailsService();
  }

  /// Trả về ID user hiện tại (hoặc null nếu chưa đăng nhập)
  Future<String?> getCurrentUserId() async {
    return _userService.getCurrentUserId();
  }

  Future<User?> getCurrentUser() async {
    return _userService.getCurrentUser();
  }

  Future<UserDetails?> getByUserId(String userId) {
    return _userService.getByUserId(userId);
  }

  Future<String?> uploadAvatar(File file) {
    return _userService.uploadAvatar(file);
  }

  Future<UserDetails> updateMyDetails({
    String? fullname,
    String? level,
    List<String>? playStyles,
    String? gender,
    DateTime? birthday,
  }) async {
    final updated = await _userService.updateMyDetails(
      fullname: fullname,
      level: level,
      playStyles: playStyles,
      gender: gender,
      birthday: birthday,
    );
    notifyListeners();
    return updated;
  }
}
