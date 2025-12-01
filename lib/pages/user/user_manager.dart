// lib/pages/user/user_manager.dart
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:badminton_booking_app/models/user.dart';
import 'package:badminton_booking_app/models/user_details.dart';
import 'package:badminton_booking_app/services/user_service.dart';

class UserManager with ChangeNotifier {
  late final UserDetailsService _userService;

  UserManager() {
    _userService = UserDetailsService();
  }

  // ====== CACHE & STATE ======
  User? _currentUser;
  UserDetails? _myDetails;
  bool _isLoading = false;

  // ====== GETTERS ĐỒNG BỘ (UI đọc trực tiếp) ======
  User? get currentUser => _currentUser;
  UserDetails? get myDetails => _myDetails;
  String? get avatarUrl => _myDetails?.avatarUrl;
  bool get isLoading => _isLoading;

  // ====== HÀNH VI CHÍNH ======
  /// Gọi khi app mở / sau đăng nhập (load user + user_details)
  Future<void> loadMe() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _userService.getCurrentUser();
      final uid = await _userService.getCurrentUserId();

      if (uid != null) {
        try {
          _myDetails = await _userService.getByUserId(uid);
        } catch (e) {
          if (kDebugMode) {
            print('loadMe getByUserId error: $e');
          }
          _myDetails = null;
        }
      } else {
        _myDetails = null;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Bắt buộc load lại (không quan tâm đang loading)
  Future<void> reloadMe() async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentUser = await _userService.getCurrentUser();
      final uid = await _userService.getCurrentUserId();
      _myDetails = (uid != null) ? await _userService.getByUserId(uid) : null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Dọn cache khi đăng xuất
  void clear() {
    _currentUser = null;
    _myDetails = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Chỉ refresh phần user_details (khi biết chắc user còn đăng nhập)
  Future<void> refreshMyDetails() async {
    final uid = await _userService.getCurrentUserId();
    if (uid == null) return;
    _myDetails = await _userService.getByUserId(uid);
    notifyListeners();
  }

  // ====== HÀM TIỆN ÍCH CHO UI (BACKWARD-COMPATIBLE) ======
  Future<String?> getMyAvatarUrl() async {
    // Nếu đã có cache thì trả ngay
    if (avatarUrl != null && avatarUrl!.isNotEmpty) return avatarUrl;
    // Không có cache: gọi service cũ
    final uid = await _userService.getCurrentUserId();
    if (uid == null) return null;
    final details = await _userService.getByUserId(uid);
    _myDetails = details;
    notifyListeners();
    return details?.avatarUrl;
  }

  // ====== CÁC API CŨ (GIỮ NGUYÊN CHO CODE KHÁC) ======
  Future<String?> getCurrentUserId() async => _userService.getCurrentUserId();
  Future<User?> getCurrentUser() async => _userService.getCurrentUser();
  Future<UserDetails?> getByUserId(String userId) =>
      _userService.getByUserId(userId);

  Future<String?> uploadAvatar(File file) async {
    final url = await _userService.uploadAvatar(file);
    if (url != null) {
      // Cập nhật cache để UI đổi ảnh ngay
      if (_myDetails != null) {
        _myDetails = _myDetails!.copyWith(avatarUrl: url);
      } else {
        // nếu chưa có record details, tạo tạm bản mới trong cache (tùy constructor của bạn)
        _myDetails = UserDetails(
          id: '', // hoặc null/khác tùy model
          userId: _currentUser?.id ?? '',
          fullname: _currentUser?.username,
          levelNumeric: 3,
          avatarUrl: url,
          level: null,
          matchTypes: const [],
          playStyleTags: const [],
          gender: null,
          birthday: null,
        );
      }
      notifyListeners();
    }
    return url;
  }

  Future<UserDetails> updateMyDetails({
    String? fullname,
    String? level,
    int? levelNumeric,
    List<String>? matchTypes,
    List<String>? playStyleTags,
    String? preferredRoleDoubles,
    String? intensity,
    int? experienceYears,
    int? playsPerWeek,
    String? gender,
    DateTime? birthday,
    String? homeCourtId,
  }) async {
    final updated = await _userService.updateMyDetails(
      fullname: fullname,
      level: level,
      levelNumeric: levelNumeric,
      matchTypes: matchTypes,
      playStyleTags: playStyleTags,
      preferredRoleDoubles: preferredRoleDoubles,
      intensity: intensity,
      experienceYears: experienceYears,
      playsPerWeek: playsPerWeek,
      gender: gender,
      birthday: birthday,
      homeCourtId: homeCourtId,
    );
    _myDetails = updated; // sync cache
    notifyListeners();
    return updated;
  }
}
