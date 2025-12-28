import 'package:badminton_booking_app/models/recruitment_applicant.dart';
import 'package:badminton_booking_app/models/recruitment_post.dart';
import 'package:badminton_booking_app/models/user_booking_view.dart';
import 'package:badminton_booking_app/utils/pocketbase_utils.dart';
import 'package:badminton_booking_app/utils/recruitment_dictionary.dart';
import 'package:pocketbase/pocketbase.dart';

import 'pocketbase_client.dart';
import 'user_service.dart';

class RecruitmentServiceException implements Exception {
  RecruitmentServiceException(this.message);
  final String message;
  @override
  String toString() => message;
}

class RecruitmentService {
  static const String recruitmentPostsCollection = 'recruitment_posts';
  static const String recruitmentApplicantsCollection =
      'recruitment_applicants';
  static const String bookingsCollection = 'court_bookings';

  Future<List<RecruitmentPost>> fetchRecruitmentPosts({
    int page = 1,
    int perPage = 30,
  }) async {
    final pocketBase = await getPocketbaseInstance();
    final currentUserId = pocketBase.authStore.record?.id;

    try {
      final result =
          await pocketBase.collection(recruitmentPostsCollection).getList(
                page: page,
                perPage: perPage,
                sort: '-created',
                expand: 'author,court',
              );

      final applicantsMap = await fetchApplicantsMap(
        pocketBase: pocketBase,
        recruitmentIds: result.items.map((e) => e.id).toList(growable: false),
      );

      return result.items
          .map(
            (record) => RecruitmentPost.fromRecord(
              record: record,
              pocketBase: pocketBase,
              currentUserId: currentUserId,
              applicants: applicantsMap[record.id] ?? const [],
            ),
          )
          .toList(growable: false);
    } on ClientException catch (error) {
      throw RecruitmentServiceException(_mapClientError(error));
    } catch (_) {
      throw RecruitmentServiceException(
        'Không thể tải bài tuyển thành viên. Vui lòng thử lại.',
      );
    }
  }

  Future<RecruitmentPost> joinRecruitment(String recruitmentId) async {
    final pocketBase = await getPocketbaseInstance();
    final currentUserId = pocketBase.authStore.record?.id;
    if (currentUserId == null) {
      throw RecruitmentServiceException('Bạn cần đăng nhập để tham gia.');
    }

    try {
      await pocketBase.collection(recruitmentApplicantsCollection).create(
        body: {
          'recruitment': recruitmentId,
          'user': currentUserId,
          'status': 'pending',
        },
      );
    } on ClientException catch (error) {
      if (error.statusCode == 400) {
        throw RecruitmentServiceException('Bạn đã tham gia bài tuyển này.');
      }
      throw RecruitmentServiceException(_mapClientError(error));
    } catch (_) {
      throw RecruitmentServiceException('Không thể tham gia bài tuyển.');
    }

    return getRecruitmentById(recruitmentId);
  }

  Future<RecruitmentPost> getRecruitmentById(String recruitmentId) async {
    final pocketBase = await getPocketbaseInstance();
    final currentUserId = pocketBase.authStore.record?.id;

    try {
      final record = await pocketBase
          .collection(recruitmentPostsCollection)
          .getOne(recruitmentId, expand: 'author,court');

      final applicantsMap = await fetchApplicantsMap(
        pocketBase: pocketBase,
        recruitmentIds: [recruitmentId],
      );

      return RecruitmentPost.fromRecord(
        record: record,
        pocketBase: pocketBase,
        currentUserId: currentUserId,
        applicants: applicantsMap[recruitmentId] ?? const [],
      );
    } on ClientException catch (error) {
      throw RecruitmentServiceException(_mapClientError(error));
    } catch (_) {
      throw RecruitmentServiceException(
        'Không thể tải thông tin bài tuyển. Vui lòng thử lại.',
      );
    }
  }

  Future<List<RecruitmentApplicant>> fetchApplicants(
    String recruitmentId,
  ) async {
    final pocketBase = await getPocketbaseInstance();
    final userDetailsService = UserDetailsService();

    try {
      final result =
          await pocketBase.collection(recruitmentApplicantsCollection).getList(
                page: 1,
                perPage: 200,
                filter: "recruitment='${_escapeFilterValue(recruitmentId)}'",
                expand: 'user',
                sort: '-created',
              );

      final applicants = <RecruitmentApplicant>[];

      for (final record in result.items) {
        final expandedUser = resolveExpandedRecord(record.expand?['user']);
        final userData = expandedUser?.data;
        final userId = (record.data['user'] as String?) ?? expandedUser?.id;
        if (userId == null || userId.isEmpty) continue;

        final details = await userDetailsService.getByUserIdWithClient(
          pocketBase,
          userId,
        );

        final avatarUrl = details?.avatarUrl ??
            resolveFileUrl(pocketBase, expandedUser, userData?['avatar']);
        final levelLabel = details?.level != null
            ? RecruitmentDictionary.skillLabelFromValue(details!.level)
            : null;
        final playStyles = (details?.matchTypes ?? const [])
            .map(RecruitmentDictionary.playStyleLabelFromValue)
            .whereType<String>()
            .toList(growable: false);

        applicants.add(
          RecruitmentApplicant(
            id: record.id,
            userId: userId,
            displayName: sanitizeDisplayName(
              userData?['username'] as String? ?? userData?['email'] as String?,
            ),
            status: (record.data['status'] as String?) ?? 'pending',
            createdAt: DateTime.parse(record.data['created'] as String),
            avatarUrl: avatarUrl,
            level: levelLabel,
            playStyles: playStyles,
          ),
        );
      }

      return applicants;
    } catch (error) {
      throw RecruitmentServiceException(
        'Không thể tải danh sách yêu cầu tham gia. Vui lòng thử lại.',
      );
    }
  }

  Future<RecruitmentPost> updateApplicantStatus({
    required String applicantId,
    required String status,
  }) async {
    final pocketBase = await getPocketbaseInstance();

    try {
      final record = await pocketBase
          .collection(recruitmentApplicantsCollection)
          .update(applicantId, body: {
        'status': status,
      });

      final recruitmentId = record.data['recruitment'] as String?;
      if (recruitmentId == null || recruitmentId.isEmpty) {
        throw RecruitmentServiceException(
            'Không tìm thấy bài tuyển liên quan.');
      }

      return getRecruitmentById(recruitmentId);
    } on ClientException catch (error) {
      throw RecruitmentServiceException(_mapClientError(error));
    } catch (_) {
      throw RecruitmentServiceException(
          'Không thể cập nhật trạng thái yêu cầu.');
    }
  }

  Future<RecruitmentPost> closeRecruitment({
    required String recruitmentId,
    DateTime? expiresAt,
  }) async {
    final pocketBase = await getPocketbaseInstance();
    try {
      final record = await pocketBase
          .collection(recruitmentPostsCollection)
          .update(recruitmentId, body: {
        'is_active': false,
        'expires_at': expiresAt?.toUtc().toIso8601String(),
      });

      return RecruitmentPost.fromRecord(
        record: record,
        pocketBase: pocketBase,
        currentUserId: pocketBase.authStore.record?.id,
      );
    } on ClientException catch (error) {
      throw RecruitmentServiceException(_mapClientError(error));
    } catch (_) {
      throw RecruitmentServiceException('Không thể đóng bài tuyển.');
    }
  }

  Future<List<UserBookingView>> listMyBookingsForDate(DateTime date) async {
    final pocketBase = await getPocketbaseInstance();
    final currentUserId = pocketBase.authStore.record?.id;
    if (currentUserId == null) {
      throw RecruitmentServiceException('Bạn cần đăng nhập để kiểm tra sân.');
    }

    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final escapedUserId = _escapeFilterValue(currentUserId);

    final filter =
        "user_id='$escapedUserId' && start_time < '${dayEnd.toUtc().toIso8601String()}' && end_time > '${dayStart.toUtc().toIso8601String()}' && status != 'cancelled' && status != 'expired'";

    try {
      final result = await pocketBase.collection(bookingsCollection).getList(
            page: 1,
            perPage: 200,
            filter: filter,
            expand: 'court_id,court_unit_id',
          );

      return result.items
          .map((record) => UserBookingView.fromRecord(record, pocketBase))
          .toList(growable: false);
    } on ClientException catch (error) {
      throw RecruitmentServiceException(_mapClientError(error));
    } catch (_) {
      throw RecruitmentServiceException(
        'Không thể kiểm tra lịch đặt sân. Vui lòng thử lại.',
      );
    }
  }

  Future<RecruitmentPost> createRecruitmentPost({
    required bool hasBookedCourt,
    required DateTime playTime,
    required DateTime expiresAt,
    required int needMembers,
    required String playStyleLabel,
    required String skillLevelLabel,
    String? note,
    String? courtId,
    String? locationNote,
  }) async {
    final pocketBase = await getPocketbaseInstance();
    final currentUserId = pocketBase.authStore.record?.id;
    if (currentUserId == null) {
      throw RecruitmentServiceException('Bạn cần đăng nhập để đăng bài tuyển.');
    }

    try {
      final record =
          await pocketBase.collection(recruitmentPostsCollection).create(
        body: {
          'author': currentUserId,
          'content': note?.trim(),
          'need_members': needMembers,
          'play_style':
              RecruitmentDictionary.playStyleValueFromLabel(playStyleLabel),
          'skill_level':
              RecruitmentDictionary.skillValueFromLabel(skillLevelLabel),
          'event_time': playTime.toUtc().toIso8601String(),
          'expires_at': expiresAt.toUtc().toIso8601String(),
          'court': hasBookedCourt ? courtId : null,
          'location_note': locationNote,
          'is_active': true,
        },
      );

      return RecruitmentPost.fromRecord(
        record: record,
        pocketBase: pocketBase,
        currentUserId: currentUserId,
      );
    } on ClientException catch (error) {
      throw RecruitmentServiceException(_mapClientError(error));
    } catch (_) {
      throw RecruitmentServiceException(
        'Không thể đăng bài tuyển thành viên. Vui lòng thử lại.',
      );
    }
  }

  Future<Map<String, List<RecordModel>>> fetchApplicantsMap({
    required PocketBase pocketBase,
    required List<String> recruitmentIds,
  }) async {
    if (recruitmentIds.isEmpty) {
      return const {};
    }

    final filters = recruitmentIds
        .map((id) => "recruitment='${_escapeFilterValue(id)}'")
        .join(' || ');

    try {
      final result =
          await pocketBase.collection(recruitmentApplicantsCollection).getList(
                page: 1,
                perPage: 500,
                filter: filters,
              );

      final map = <String, List<RecordModel>>{};
      for (final record in result.items) {
        final recruitmentId = (record.data['recruitment'] as String?) ?? '';
        if (recruitmentId.isEmpty) continue;
        map.putIfAbsent(recruitmentId, () => []).add(record);
      }
      return map;
    } catch (_) {
      return const {};
    }
  }

  String _mapClientError(ClientException error) {
    if (error.response != null && error.response['message'] is String) {
      return error.response['message'] as String;
    }
    return 'Có lỗi xảy ra. Vui lòng thử lại.';
  }

  String _escapeFilterValue(String input) {
    return input.replaceAll("'", "\\'");
  }
}

class BookedCourtOption {
  const BookedCourtOption({
    required this.bookingView,
  });

  final UserBookingView bookingView;

  String get id => bookingView.booking.id;

  String get courtId => bookingView.booking.courtId;

  String get displayName {
    final name = bookingView.courtName ?? 'Sân chưa rõ';
    final unit = bookingView.courtUnitLabel != null
        ? ' - ${bookingView.courtUnitLabel}'
        : '';
    final start = bookingView.booking.startTime.toLocal();
    final end = bookingView.booking.endTime.toLocal();
    final timeLabel =
        '${_twoDigits(start.hour)}:${_twoDigits(start.minute)} - ${_twoDigits(end.hour)}:${_twoDigits(end.minute)}';
    return '$name$unit ($timeLabel)';
  }

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');
}
