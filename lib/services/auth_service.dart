import 'dart:async';

import 'package:pocketbase/pocketbase.dart';

import '../models/user.dart';

import 'pocketbase_client.dart';

class AuthService {
  void Function(User? user)? onAuthChange;
  StreamSubscription<dynamic>? _authSubscription;

  AuthService({this.onAuthChange}) {
    if (onAuthChange != null) {
      getPocketbaseInstance().then((pb) {
        _authSubscription = pb.authStore.onChange.listen((event) {
          onAuthChange!(
            event.record == null ? null : User.fromJson(event.record!.toJson()),
          );
        });
      });
    }
  }

  Future<void> _ensureUserDetailsRecord(PocketBase pb, String userId) async {
    try {
      await pb.collection('user_details').getFirstListItem("user_id='$userId'");
    } on ClientException catch (error) {
      final response = error.response;
      final code =
          response is Map<String, dynamic> ? response['code'] as int? : null;
      if (code == 404) {
        await pb.collection('user_details').create(body: {'user_id': userId});
      } else {
        rethrow;
      }
    }
  }

  Future<User> signup(
    String email,
    String password,
    String phone,
    String username,
  ) async {
    final pb = await getPocketbaseInstance();

    try {
      // ============================
      // 1) Kiểm tra email tồn tại chưa
      // ============================
      try {
        await pb.collection('users').getFirstListItem(
              "email = '$email'",
            );
        throw Exception("Email đã được sử dụng.");
      } catch (e) {
        if (e is! ClientException || e.response['code'] != 404) {
          rethrow; // lỗi thật không phải 404 → quăng lỗi
        }
      }

      // ============================
      // 2) Kiểm tra phone tồn tại chưa
      // ============================
      try {
        await pb.collection('users').getFirstListItem(
              "phone = '$phone'",
            );
        throw Exception("Số điện thoại đã được sử dụng.");
      } catch (e) {
        if (e is! ClientException || e.response['code'] != 404) {
          rethrow; // lỗi thật không phải 404 → quăng lỗi
        }
      }

      // ============================
      // 3) Tạo user mới
      // ============================
      await pb.collection('users').create(body: {
        'email': email,
        'password': password,
        'passwordConfirm': password,
        'phone': phone,
        'username': username,
        'role': 'user',
      });

      // ============================
      // 4) Đăng nhập luôn sau khi tạo
      // ============================
      final authResult =
          await pb.collection('users').authWithPassword(email, password);
      final userRecord = authResult.record;

      // ============================
      // 5) Tạo user_details nếu chưa có
      // ============================
      await _ensureUserDetailsRecord(pb, userRecord.id);

      // ============================
      // 6) Gửi email verify
      // ============================
      await pb.collection('users').requestVerification(email);

      return User.fromJson(userRecord.toJson());
    } catch (error) {
      if (error is ClientException) {
        final msg = error.response['message'] ?? 'Có lỗi xảy ra.';
        throw Exception(msg);
      }
      throw Exception(error.toString());
    }
  }

  Future<User> login(String email, String password) async {
    final pb = await getPocketbaseInstance();

    try {
      final authRecord =
          await pb.collection('users').authWithPassword(email, password);
      return User.fromJson(authRecord.record.toJson());
    } catch (error) {
      if (error is ClientException) {
        throw Exception(error.response['message']);
      }
      throw Exception('An error occurred');
    }
  }

  Future<void> logout() async {
    final pb = await getPocketbaseInstance();
    pb.authStore.clear();
  }

  Future<User?> getUserFromStore() async {
    final pb = await getPocketbaseInstance();
    final model = pb.authStore.record;

    if (model == null || !pb.authStore.isValid) {
      return null;
    }

    return User.fromJson(model.toJson());
  }

  void dispose() {
    _authSubscription?.cancel();
    _authSubscription = null;
  }
}
