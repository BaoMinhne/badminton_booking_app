import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:pocketbase/pocketbase.dart';

import '../models/user.dart';
import '../models/user_details.dart';
import 'pocketbase_client.dart';

class UserDetailsService {
  static const collection = 'user_details';

  Future<String?> getCurrentUserId() async {
    final pb = await getPocketbaseInstance();
    return pb.authStore.record?.id;
  }

  Future<String?> getCurrentUsername() async {
    final pb = await getPocketbaseInstance();
    return pb.authStore.record?.data['username'];
  }

  /// (Tuỳ chọn) Lấy user hiện tại dạng model, nếu bạn cần
  Future<User?> getCurrentUser() async {
    final pb = await getPocketbaseInstance();
    final rec = pb.authStore.record;
    if (rec == null) return null;

    return User.fromJson(rec.toJson());
  }

  Future<RecordModel> _ensureUserDetails(PocketBase pb, String userId) async {
    try {
      return await pb
          .collection(collection)
          .getFirstListItem("user_id='$userId'");
    } catch (_) {
      // chưa có -> tạo mới
      return await pb.collection(collection).create(body: {'user_id': userId});
    }
  }

  /// Lấy user_details theo userId
  Future<UserDetails?> getByUserId(String userId) async {
    try {
      final pb = await getPocketbaseInstance();
      final rec = await pb.collection(collection).getFirstListItem(
            "user_id='$userId'",
          );
      final data = rec.toJson();
      final avatarName = (data['avatar'] as String?) ?? '';
      final avatarUrl = avatarName.isEmpty
          ? null
          : pb.files.getUrl(rec, avatarName).toString();
      return UserDetails.fromJson(data, avatarUrl: avatarUrl);
    } catch (e) {
      throw Exception('getByUserId error: $e');
    }
  }

  Future<String?> uploadAvatar(File file) async {
    final pb = await getPocketbaseInstance();
    final userId = pb.authStore.record?.id;
    if (userId == null) return null;

    try {
      // đảm bảo có record user_details
      final details = await _ensureUserDetails(pb, userId);

      // chuẩn bị MultipartFile như trong ProductsService
      final bytes = await file.readAsBytes();
      final filename = p.basename(file.path);

      final multipart = http.MultipartFile.fromBytes(
        'avatar', // tên field file trong schema
        bytes,
        filename: filename,
      );

      // cập nhật record với file mới
      final updated = await pb.collection(collection).update(
        details.id,
        body: {
          // có thể gửi thêm các field khác ở đây nếu cần
          'user_id': userId,
        },
        files: [multipart],
      );

      final avatarName = updated.getStringValue('avatar');
      if (avatarName.isEmpty) return null;

      final url = pb.files.getUrl(updated, avatarName).toString();
      return url;
    } catch (e) {
      print('uploadAvatar error: $e');

      return null;
    }
  }

  /// Lấy user_details của chính mình (tiện dụng, không cần truyền id)
  Future<UserDetails?> getMyDetails() async {
    final myId = await getCurrentUserId();
    if (myId == null) return null;
    return getByUserId(myId);
  }
}
