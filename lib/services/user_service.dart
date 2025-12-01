import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:pocketbase/pocketbase.dart';

import '../models/friend_search_result.dart';
import '../models/user.dart';
import '../models/user_details.dart';
import 'pocketbase_client.dart';

class UserDetailsService {
  static const collection = 'user_details';
  static const Map<String, int> _levelToNumeric = {
    'Beginner': 1,
    'Lower Intermediate': 2,
    'Intermediate': 3,
    'Upper Intermediate': 4,
    'Advanced': 5,
  };

  static const Map<int, String> _numericToLevel = {
    1: 'Beginner',
    2: 'Lower Intermediate',
    3: 'Intermediate',
    4: 'Upper Intermediate',
    5: 'Advanced',
  };

  int _mapLevelToNumeric(String? level, int fallback) {
    if (level == null || level.trim().isEmpty) return fallback;
    return _levelToNumeric[level.trim()] ?? fallback;
  }

  String? _mapNumericToLevel(int? levelNumeric) {
    if (levelNumeric == null) return null;
    return _numericToLevel[levelNumeric];
  }

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
      final record = await pb
          .collection(collection)
          .getFirstListItem("user_id='$userId'");

      // Nếu record cũ thiếu các field bắt buộc mới thì cập nhật giá trị mặc định
      final levelNumeric = (record.data['level_numeric'] as num?)?.toInt();
      final level = (record.data['level'] as String?)?.trim();
      final matchTypes = (record.data['match_types'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[];
      final playStyleTags = (record.data['play_style_tags'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[];

      if (levelNumeric == null) {
        return await pb.collection(collection).update(
          record.id,
          body: {
            'user_id': userId,
            'level_numeric': _mapLevelToNumeric(level, 3),
            'level': level ?? _mapNumericToLevel(3),
            'match_types': matchTypes,
            'play_style_tags': playStyleTags,
          },
        );
      }

      return record;
    } catch (_) {
      // chưa có -> tạo mới
      return await pb.collection(collection).create(body: {
        'user_id': userId,
        'level_numeric': 3,
        'level': _mapNumericToLevel(3),
        'match_types': const <String>[],
        'play_style_tags': const <String>[],
      });
    }
  }

  /// Lấy user_details theo userId
  Future<UserDetails?> getByUserId(String userId) async {
    try {
      final pb = await getPocketbaseInstance();
      return await getByUserIdWithClient(pb, userId);
    } catch (e) {
      throw Exception('getByUserId error: $e');
    }
  }

  Future<UserDetails?> getByUserIdWithClient(
    PocketBase pb,
    String userId,
  ) async {
    try {
      // Luôn đảm bảo có record user_details (có thì lấy, chưa có thì tạo)
      final rec = await _ensureUserDetails(pb, userId);

      final data = rec.toJson();
      data['level'] ??=
          _mapNumericToLevel((data['level_numeric'] as num?)?.toInt());
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
          // đảm bảo các field bắt buộc không bị null trên record cũ
          'level_numeric':
              (details.data['level_numeric'] as num?)?.toInt() ?? 3,
          'match_types': (details.data['match_types'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              const <String>[],
          'play_style_tags': (details.data['play_style_tags'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              const <String>[],
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

  Future<List<FriendSearchResult>> searchUsers(String keyword) async {
    final term = keyword.trim();
    if (term.isEmpty) return const <FriendSearchResult>[];

    final pb = await getPocketbaseInstance();
    final currentUserId = pb.authStore.record?.id;
    final sanitized = term.replaceAll("'", "\\'");

    final result = await pb.collection('users').getList(
      filter: """
      (username ~ '%$sanitized%' 
      || email ~ '%$sanitized%' 
      || phone ~ '%$sanitized%')
      && role = 'user'
      ${currentUserId != null ? "&& id != '$currentUserId'" : ""}
    """,
      perPage: 20,
    );

    final detailFutures = result.items.map((userRecord) async {
      final user = User.fromJson(userRecord.toJson());
      try {
        final details = await getByUserIdWithClient(pb, user.id);
        return FriendSearchResult(user: user, details: details);
      } catch (_) {
        return FriendSearchResult(user: user);
      }
    });

    return Future.wait(detailFutures);
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
    final pb = await getPocketbaseInstance();
    final userId = pb.authStore.record?.id;

    if (userId == null) {
      throw Exception('Bạn chưa đăng nhập.');
    }

    final record = await _ensureUserDetails(pb, userId);

    final currentLevelNumeric =
        (record.data['level_numeric'] as num?)?.toInt() ?? 3;
    final List<String> currentMatchTypes =
        (record.data['match_types'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const <String>[];
    final List<String> currentPlayStyleTags =
        (record.data['play_style_tags'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const <String>[];
    final String? currentPreferredRole =
        (record.data['preferred_role_doubles'] as String?)?.trim();
    final String? currentIntensity =
        (record.data['intensity'] as String?)?.trim();
    final int? currentExperienceYears =
        (record.data['experience_years'] as num?)?.toInt();
    final int? currentPlaysPerWeek =
        (record.data['plays_per_week'] as num?)?.toInt();
    final String? currentHomeCourt =
        (record.data['home_court'] as String?)?.trim();
    final String? sanitizedFullname =
        fullname != null && fullname.trim().isNotEmpty ? fullname.trim() : null;
    final String? sanitizedLevel =
        level != null && level.trim().isNotEmpty ? level.trim() : null;
    final int sanitizedLevelNumeric =
        levelNumeric ?? _mapLevelToNumeric(sanitizedLevel, currentLevelNumeric);
    final String? sanitizedGender =
        gender != null && gender.trim().isNotEmpty ? gender.trim() : null;
    final List<String> sanitizedMatchTypes = (matchTypes ?? currentMatchTypes)
        .where((style) => style.trim().isNotEmpty)
        .map((style) => style.trim())
        .toList();
    final List<String> sanitizedPlayStyleTags =
        (playStyleTags ?? currentPlayStyleTags)
            .where((tag) => tag.trim().isNotEmpty)
            .map((tag) => tag.trim())
            .toList();
    final String? sanitizedPreferredRole =
        (preferredRoleDoubles != null && preferredRoleDoubles.trim().isNotEmpty)
            ? preferredRoleDoubles.trim()
            : currentPreferredRole;
    final String? sanitizedIntensity =
        (intensity != null && intensity.trim().isNotEmpty)
            ? intensity.trim()
            : currentIntensity;
    final int? sanitizedExperienceYears =
        experienceYears ?? currentExperienceYears;
    final int? sanitizedPlaysPerWeek = playsPerWeek ?? currentPlaysPerWeek;
    final String? sanitizedHomeCourt =
        (homeCourtId != null && homeCourtId.trim().isNotEmpty)
            ? homeCourtId.trim()
            : currentHomeCourt;

    final updated = await pb.collection(collection).update(
      record.id,
      body: {
        'user_id': userId,
        'fullname': sanitizedFullname,
        'level': sanitizedLevel ?? _mapNumericToLevel(sanitizedLevelNumeric),
        'level_numeric': sanitizedLevelNumeric,
        'match_types': sanitizedMatchTypes,
        'play_style_tags': sanitizedPlayStyleTags,
        'gender': sanitizedGender,
        'birthday': birthday?.toIso8601String(),
        'preferred_role_doubles': sanitizedPreferredRole,
        'intensity': sanitizedIntensity,
        'experience_years': sanitizedExperienceYears,
        'plays_per_week': sanitizedPlaysPerWeek,
        'home_court': sanitizedHomeCourt,
      },
    );

    final data = updated.toJson();
    final avatarName = (data['avatar'] as String?) ?? '';
    final avatarUrl = avatarName.isEmpty
        ? null
        : pb.files.getUrl(updated, avatarName).toString();

    return UserDetails.fromJson(data, avatarUrl: avatarUrl);
  }
}
