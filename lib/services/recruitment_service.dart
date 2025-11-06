import 'package:pocketbase/pocketbase.dart';

import '../models/recruitment_post.dart';
import 'pocketbase_client.dart';

class RecruitmentServiceException implements Exception {
  RecruitmentServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class RecruitmentService {
  static const String collection = 'recruitment_posts';

  Future<List<RecruitmentPost>> fetchRecruitmentPosts({
    int page = 1,
    int perPage = 20,
  }) async {
    final client = await getPocketbaseInstance();
    final nowIso = DateTime.now().toUtc().toIso8601String();

    try {
      final result = await client.collection(collection).getList(
            page: page,
            perPage: perPage,
            sort: '-created',
            filter:
                "is_active = true && (expires_at = '' || expires_at >= '$nowIso')",
            expand: 'author,court',
          );

      final futures = result.items.map((record) async {
        final joined = await _countApplicants(client, record.id);
        return RecruitmentPost.fromRecord(
          record,
          joinedCount: joined,
        );
      }).toList();

      return Future.wait(futures);
    } on ClientException catch (error) {
      throw RecruitmentServiceException(_mapClientError(error));
    } catch (_) {
      throw RecruitmentServiceException(
        'Không thể tải danh sách bài tuyển thành viên. Vui lòng thử lại.',
      );
    }
  }

  Future<RecruitmentPost> createRecruitmentPost({
    required String content,
    required int requiredMembers,
    String? courtId,
    DateTime? eventTime,
    String? skillLevel,
    String? playStyle,
    String? locationNote,
  }) async {
    final client = await getPocketbaseInstance();
    final authorId = client.authStore.record?.id;

    if (authorId == null || authorId.isEmpty) {
      throw RecruitmentServiceException('Bạn cần đăng nhập để đăng bài tuyển.');
    }

    try {
      final body = <String, dynamic>{
        'author': authorId,
        'content': content.trim(),
        'need_members': requiredMembers,
        'is_active': true,
      };

      if (courtId != null && courtId.isNotEmpty) {
        body['court'] = courtId;
      }

      if (eventTime != null) {
        body['event_time'] = eventTime.toUtc().toIso8601String();
        body['expires_at'] = eventTime.toUtc().toIso8601String();
      }

      if (skillLevel != null && skillLevel.trim().isNotEmpty) {
        body['skill_level'] = skillLevel.trim();
      }

      if (playStyle != null && playStyle.trim().isNotEmpty) {
        body['play_style'] = playStyle.trim();
      }

      if (locationNote != null && locationNote.trim().isNotEmpty) {
        body['location_note'] = locationNote.trim();
      }

      final record = await client.collection(collection).create(
            body: body,
          );

      final refreshed = await client.collection(collection).getOne(
            record.id,
            expand: 'author,court',
          );

      return RecruitmentPost.fromRecord(refreshed);
    } on ClientException catch (error) {
      throw RecruitmentServiceException(_mapClientError(error));
    } catch (error) {
      throw RecruitmentServiceException(
        'Không thể đăng bài tuyển thành viên. Lỗi: $error',
      );
    }
  }

  Future<int> _countApplicants(PocketBase client, String recruitmentId) async {
    final escapedId = _escapeFilterValue(recruitmentId);

    try {
      final result = await client.collection('recruitment_applicants').getList(
            page: 1,
            perPage: 1,
            filter: "recruitment='$escapedId'",
          );
      return result.totalItems;
    } catch (_) {
      return 0;
    }
  }

  String _escapeFilterValue(String value) {
    return value.replaceAll("'", "\\'");
  }

  String _mapClientError(ClientException error) {
    if (error.response['message'] is String) {
      return error.response['message'] as String;
    }
    if (error.statusCode == 401) {
      return 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.';
    }
    if (error.statusCode == 403) {
      return 'Bạn không có quyền thực hiện thao tác này.';
    }
    return 'Có lỗi xảy ra. Mã lỗi: ${error.statusCode ?? 'không xác định'}';
  }
}
