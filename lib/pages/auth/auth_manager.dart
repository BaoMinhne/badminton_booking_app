import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../models/user.dart';
import '../../services/auth_service.dart';

class AuthManager with ChangeNotifier {
  late final AuthService _authService;
  User? _loggedInUser;
  bool _isChecking = true;

  AuthManager() {
    _authService = AuthService(onAuthChange: _handleAuthChange);
    Future.microtask(tryAutoLogin);
  }

  bool get isAuth => _loggedInUser != null;

  bool get isChecking => _isChecking;

  User? get user => _loggedInUser;

  void _handleAuthChange(User? user) {
    _loggedInUser = user;
    notifyListeners();
  }

  Future<User> signup(
    String email,
    String password,
    String phone,
    String username,
  ) async {
    final user = await _authService.signup(email, password, phone, username);
    _loggedInUser = user;
    notifyListeners();
    return user;
  }

  Future<User> login(String email, String password) async {
    final user = await _authService.login(email, password);
    _loggedInUser = user;
    notifyListeners();
    return user;
  }

  Future<bool> tryAutoLogin() async {
    try {
      final user = await _authService.getUserFromStore();
      _loggedInUser = user;
      return user != null;
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _loggedInUser = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authService.dispose();
    super.dispose();
  }
}
