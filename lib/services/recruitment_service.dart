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
  static const recruitmentCollection = 'recruitment_posts';
  static const applicantCollection = 'recruitment_applicants';

  Future<List<RecruitmentPost>> fetchRecruitmentPosts({
    String? currentUserId,
  }) async {
    final pocketBase = await getPocketbaseInstance();
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final filter =
        "is_active = true && (expires_at = null || expires_at = '' || expires_at >= '$nowIso')";

    try {
      final result = await pocketBase.collection(recruitmentCollection).getList(
            filter: filter,
            expand:
                'author,court,recruitment_applicants(recruitment),recruitment_applicants(recruitment).user',
            sort: '-created',
            perPage: 200,
          );
      return result.items
          .map((record) => RecruitmentPost.fromRecord(
                record,
                pocketBase,
                currentUserId: currentUserId,
              ))
          .toList(growable: false);
    } on ClientException catch (error) {
      throw RecruitmentServiceException(_mapClientException(error));
    } catch (_) {
      throw RecruitmentServiceException(
        'Không thể tải bài tuyển thành viên. Vui lòng thử lại.',
      );
    }
  }

  Future<RecruitmentPost> createRecruitmentPost({
    required String authorId,
    required String content,
    required DateTime eventTime,
    required int targetMemberCount,
    String? courtId,
    String? skillLevel,
    String? playStyle,
    String? locationNote,
    DateTime? expiresAt,
  }) async {
    final pocketBase = await getPocketbaseInstance();

    final body = <String, dynamic>{
      'author': authorId,
      'content': content.trim(),
      'event_time': eventTime.toUtc().toIso8601String(),
      'need_members': targetMemberCount,
      'is_active': true,
    };

    if (courtId != null && courtId.isNotEmpty) {
      body['court'] = courtId;
    }
    if (skillLevel != null && skillLevel.isNotEmpty) {
      body['skill_level'] = skillLevel;
    }
    if (playStyle != null && playStyle.isNotEmpty) {
      body['play_style'] = playStyle;
    }
    if (locationNote != null && locationNote.isNotEmpty) {
      body['location_note'] = locationNote.trim();
    }
    if (expiresAt != null) {
      body['expires_at'] = expiresAt.toUtc().toIso8601String();
    }

    try {
      final record = await pocketBase
          .collection(recruitmentCollection)
          .create(body: body);
      final fetched = await pocketBase.collection(recruitmentCollection).getOne(
            record.id,
            expand:
                'author,court,recruitment_applicants(recruitment),recruitment_applicants(recruitment).user',
          );
      return RecruitmentPost.fromRecord(
        fetched,
        pocketBase,
        currentUserId: authorId,
      );
    } on ClientException catch (error) {
      throw RecruitmentServiceException(_mapClientException(error));
    } catch (_) {
      throw RecruitmentServiceException(
        'Không thể đăng bài tuyển thành viên. Vui lòng thử lại.',
      );
    }
  }

  Future<void> joinRecruitment({
    required String recruitmentId,
    required String userId,
  }) async {
    final pocketBase = await getPocketbaseInstance();

    try {
      await pocketBase.collection(applicantCollection).create(body: {
        'recruitment': recruitmentId,
        'user': userId,
      });
    } on ClientException catch (error) {
      throw RecruitmentServiceException(_mapClientException(error));
    } catch (_) {
      throw RecruitmentServiceException(
        'Không thể tham gia bài tuyển. Vui lòng thử lại.',
      );
    }
  }

  String _mapClientException(ClientException error) {
    final response = error.response;
    if (response is Map<String, dynamic>) {
      final message = response['message'] as String?;
      if (message != null && message.trim().isNotEmpty) {
        return message.trim();
      }

      final data = response['data'];
      if (data is Map<String, dynamic>) {
        final recruitmentError = data['recruitment'];
        final userError = data['user'];
        final msgBuffer = StringBuffer();
        if (recruitmentError is Map<String, dynamic>) {
          final message = recruitmentError['message'] as String?;
          if (message != null && message.trim().isNotEmpty) {
            msgBuffer.write(message.trim());
          }
        }
        if (userError is Map<String, dynamic>) {
          final message = userError['message'] as String?;
          if (message != null && message.trim().isNotEmpty) {
            if (msgBuffer.isNotEmpty) msgBuffer.write('\n');
            msgBuffer.write(message.trim());
          }
        }
        if (msgBuffer.isNotEmpty) {
          return msgBuffer.toString();
        }
      }
    }
    return 'Đã có lỗi xảy ra. Vui lòng thử lại.';
  }
}
