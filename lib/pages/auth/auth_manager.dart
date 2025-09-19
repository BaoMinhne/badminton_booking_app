import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../models/user.dart';
import '../../services/auth_service.dart';

class AuthManager with ChangeNotifier {
  late final AuthService _authService;

  User? _loggedInUser;

  AuthManager() {
    _authService = AuthService(onAuthChange: (User? user) {
      _loggedInUser = user;
      notifyListeners();
    });
  }

  bool get isAuth {
    return _loggedInUser != null;
  }

  User? get user {
    return _loggedInUser;
  }

  Future<User> signup(
    String email,
    String password,
    String phone,
    String username,
  ) {
    return _authService.signup(email, password, phone, username);
  }

  Future<User> login(String email, String password) {
    return _authService.login(email, password);
  }

  Future<User> loginWithGoogle() {
    return _authService.loginWithGoogle();
  }

  Future<bool> tryAutoLogin() async {
    final user = await _authService.getUserFromStore();
    if (user != null) {
      _loggedInUser = user;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    return _authService.logout();
  }
}
