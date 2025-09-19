import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:pocketbase/pocketbase.dart';

import '../models/user.dart';

import 'pocketbase_client.dart';

class AuthService {
  static const _googleCallbackScheme = 'com.example.badminton_booking_app';
  static const _googleRedirectUrl = '$_googleCallbackScheme://oauth-callback';

  void Function(User? user)? onAuthChange;

  AuthService({this.onAuthChange}) {
    if (onAuthChange != null) {
      getPocketbaseInstance().then((pb) {
        pb.authStore.onChange.listen((event) {
          onAuthChange!(event.record == null
              ? null
              : User.fromJson(event.record!.toJson()));
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
      // 1) Tạo user auth
      await pb.collection('users').create(body: {
        'email': email,
        'password': password,
        'passwordConfirm': password,
        'phone': phone,
        'username': username,
        'role': 'user',
      });

      final authResult =
          await pb.collection('users').authWithPassword(email, password);
      final userRecord = authResult.record;

      await _ensureUserDetailsRecord(pb, userRecord.id);

      await pb.collection('users').requestVerification(email);

      return User.fromJson(userRecord.toJson());
    } catch (error) {
      if (error is ClientException) {
        throw Exception(error.response['message']);
      }
      throw Exception('An error occurred');
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

  Future<User> loginWithGoogle() async {
    final pb = await getPocketbaseInstance();

    try {
      final authData = await pb.collection('users').authWithOAuth2(
            'google',
            (url) async {
          final result = await FlutterWebAuth2.authenticate(
            url: url.toString(),
            callbackUrlScheme: _googleCallbackScheme,
          );
          return Uri.parse(result);
        },
        redirectUrl: _googleRedirectUrl,
      );

      final record = authData.record;
      if (record == null) {
        throw Exception('Không thể lấy thông tin người dùng từ Google.');
      }

      await _ensureUserDetailsRecord(pb, record.id);

      return User.fromJson(record.toJson());
    } on PlatformException catch (error) {
      if (error.code == 'CANCELED' || error.code == 'CANCELLED') {
        throw Exception('Đăng nhập Google đã bị hủy.');
      }
      throw Exception(error.message ?? 'Không thể đăng nhập bằng Google.');
    } catch (error) {
      if (error is ClientException) {
        final response = error.response;
        if (response is Map<String, dynamic>) {
          final message = response['message']?.toString();
          if (message != null && message.isNotEmpty) {
            throw Exception(message);
          }
        }
        throw Exception(error.message ?? 'Không thể đăng nhập bằng Google.');
      }
      throw Exception('Không thể đăng nhập bằng Google.');
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
}
