import 'package:badminton_booking_app/models/court.dart';
import 'package:badminton_booking_app/models/invitation.dart';
import 'package:badminton_booking_app/models/recruitment_post.dart';
import 'package:badminton_booking_app/models/user_booking_view.dart';
import 'package:badminton_booking_app/services/booking_service.dart';
import 'package:badminton_booking_app/services/court_service.dart';
import 'package:badminton_booking_app/services/recruitment_service.dart';
import 'package:pocketbase/pocketbase.dart';

import '../utils/pocketbase_utils.dart';
import 'pocketbase_client.dart';

class InvitationServiceException implements Exception {
  InvitationServiceException(this.message);
  final String message;

  @override
  String toString() => message;
}

class InvitationComposerData {
  InvitationComposerData({
    required this.recruitments,
    required this.bookings,
    required this.courts,
  });

  final List<RecruitmentPost> recruitments;
  final List<UserBookingView> bookings;
  final List<Court> courts;
}

class InvitationService {
  static const String collection = 'invitations';

  final RecruitmentService _recruitmentService;
  final BookingService _bookingService;
  final CourtService _courtService;

  InvitationService({
    RecruitmentService? recruitmentService,
    BookingService? bookingService,
    CourtService? courtService,
  })  : _recruitmentService = recruitmentService ?? RecruitmentService(),
        _bookingService = bookingService ?? BookingService(),
        _courtService = courtService ?? CourtService();

  Future<InvitationComposerData> loadComposerData() async {
    final pb = await getPocketbaseInstance();
    final currentUserId = pb.authStore.record?.id;
    if (currentUserId == null) {
      throw InvitationServiceException('Bạn cần đăng nhập để gửi lời mời.');
    }

    final recruitments = await _listMyRecruitments(pb, currentUserId);
    final bookings = await _bookingService.listUserBookings(
      userId: currentUserId,
      startTimeInclusive: DateTime.now(),
      endTimeExclusive: DateTime.now().add(const Duration(days: 14)),
    );
    final courts = await _courtService.listCourts(perPage: 50);

    return InvitationComposerData(
      recruitments: recruitments,
      bookings: bookings,
      courts: courts,
    );
  }

  Future<List<Invitation>> fetchIncoming() async {
    final pb = await getPocketbaseInstance();
    final currentUserId = pb.authStore.record?.id;
    if (currentUserId == null) {
      return const <Invitation>[];
    }

    try {
      final result = await pb.collection(collection).getList(
            filter:
                "to_user='${_escape(currentUserId)}' || from_user='${_escape(currentUserId)}'",
            sort: '-created',
            expand:
                'from_user,to_user,recruitment,recruitment.court,booking,booking.court_id,court',
          );

      return result.items
          .map((record) => Invitation.fromRecord(
                record,
                pb,
                viewerId: currentUserId,
              ))
          .toList(growable: false);
    } on ClientException catch (error) {
      throw InvitationServiceException(_mapClientError(error));
    } catch (_) {
      throw InvitationServiceException(
          'Không thể tải danh sách lời mời. Vui lòng thử lại.');
    }
  }

  Future<Invitation> sendRecruitmentInvite({
    required String toUserId,
    required String recruitmentId,
    String? message,
  }) async {
    return _createInvitation(
      toUserId: toUserId,
      type: 'recruitment',
      body: {
        'recruitment': recruitmentId,
        'message': message,
      },
    );
  }

  Future<Invitation> sendBookingInvite({
    required String toUserId,
    required UserBookingView booking,
    String? message,
  }) async {
    return _createInvitation(
      toUserId: toUserId,
      type: 'booking',
      body: {
        'booking': booking.id,
        'court': booking.courtId,
        'start_time': booking.startTime?.toUtc().toIso8601String(),
        'end_time': booking.endTime?.toUtc().toIso8601String(),
        'message': message,
      },
    );
  }

  Future<Invitation> sendProposedInvite({
    required String toUserId,
    required DateTime startTime,
    DateTime? endTime,
    String? courtId,
    String? message,
  }) async {
    return _createInvitation(
      toUserId: toUserId,
      type: 'proposed',
      body: {
        'court': courtId,
        'start_time': startTime.toUtc().toIso8601String(),
        if (endTime != null) 'end_time': endTime.toUtc().toIso8601String(),
        'message': message,
      },
    );
  }

  Future<Invitation> respond({
    required Invitation invitation,
    required bool accept,
  }) async {
    final pb = await getPocketbaseInstance();
    try {
      final record = await pb.collection(collection).update(
        invitation.id,
        body: {'status': accept ? 'accepted' : 'rejected'},
      );

      if (accept && invitation.recruitmentId != null) {
        await _upsertRecruitmentApplicant(
          recruitmentId: invitation.recruitmentId!,
          userId: invitation.toUserId,
          pb: pb,
        );
      }

      return Invitation.fromRecord(record, pb);
    } on InvitationServiceException {
      rethrow;
    } on ClientException catch (error) {
      throw InvitationServiceException(_mapClientError(error));
    } catch (_) {
      throw InvitationServiceException('Không thể cập nhật lời mời.');
    }
  }

  Future<Invitation> _createInvitation({
    required String toUserId,
    required String type,
    required Map<String, dynamic> body,
  }) async {
    final pb = await getPocketbaseInstance();
    final fromUserId = pb.authStore.record?.id;
    if (fromUserId == null) {
      throw InvitationServiceException('Bạn cần đăng nhập để gửi lời mời.');
    }

    try {
      final record = await pb.collection(collection).create(body: {
        'from_user': fromUserId,
        'to_user': toUserId,
        'type': type,
        'status': 'pending',
        ...body,
      });
      final hydrated = await pb.collection(collection).getOne(
            record.id,
            expand:
                'from_user,to_user,recruitment,recruitment.court,booking,booking.court_id,court',
          );
      return Invitation.fromRecord(hydrated, pb, viewerId: fromUserId);
    } on ClientException catch (error) {
      throw InvitationServiceException(_mapClientError(error));
    } catch (_) {
      throw InvitationServiceException('Không thể gửi lời mời.');
    }
  }

  Future<void> _upsertRecruitmentApplicant({
    required String recruitmentId,
    required String userId,
    required PocketBase pb,
  }) async {
    final filter =
        "recruitment='${_escape(recruitmentId)}' && user='${_escape(userId)}'";

    try {
      RecordModel? existing;
      try {
        existing = await pb
            .collection(RecruitmentService.recruitmentApplicantsCollection)
            .getFirstListItem(filter);
      } on ClientException catch (error) {
        if (error.statusCode == 404) {
          existing = null;
        } else {
          throw InvitationServiceException(_mapClientError(error));
        }
      }

      if (existing == null) {
        try {
          await pb
              .collection(RecruitmentService.recruitmentApplicantsCollection)
              .create(body: {
            'recruitment': recruitmentId,
            'user': userId,
            'status': 'accepted',
          });
        } on ClientException catch (error) {
          // Nếu record đã tồn tại (hoặc đột biến khác) khiến create thất bại,
          // thử tìm lại và cập nhật để tránh làm hỏng luồng accept.
          try {
            final fallback = await pb
                .collection(RecruitmentService.recruitmentApplicantsCollection)
                .getFirstListItem(filter);
            await pb
                .collection(RecruitmentService.recruitmentApplicantsCollection)
                .update(fallback.id, body: {
              'status': 'accepted',
            });
          } on ClientException catch (nested) {
            throw InvitationServiceException(_mapClientError(nested));
          }
        }
      } else {
        await pb
            .collection(RecruitmentService.recruitmentApplicantsCollection)
            .update(existing.id, body: {
          'status': 'accepted',
        });
      }
    } on ClientException catch (error) {
      throw InvitationServiceException(_mapClientError(error));
    } catch (_) {
      throw InvitationServiceException(
          'Không thể thêm thành viên vào bài tuyển.');
    }
  }

  Future<List<RecruitmentPost>> _listMyRecruitments(
    PocketBase pb,
    String userId,
  ) async {
    try {
      final result = await pb
          .collection(RecruitmentService.recruitmentPostsCollection)
          .getList(
            page: 1,
            perPage: 50,
            filter: "author='${_escape(userId)}' && is_active=true",
            expand: 'court',
          );

      final applicantsMap = await _recruitmentService.fetchApplicantsMap(
        pocketBase: pb,
        recruitmentIds: result.items.map((e) => e.id).toList(growable: false),
      );

      final today = DateTime.now();

      final posts = result.items
          .map(
        (record) => RecruitmentPost.fromRecord(
          record: record,
          pocketBase: pb,
          currentUserId: userId,
          applicants: applicantsMap[record.id] ?? const [],
        ),
      )
          .where((post) {
        final eventTime = post.eventTime;
        if (eventTime == null) return false;

        final matchesToday = eventTime.year == today.year &&
            eventTime.month == today.month &&
            eventTime.day == today.day;

        final hasCapacity = post.requiredPlayers <= 0
            ? true
            : post.joinedPlayers < post.requiredPlayers;

        return matchesToday && post.isActive && hasCapacity;
      }).toList(growable: false);

      return posts;
    } on ClientException catch (error) {
      throw InvitationServiceException(_mapClientError(error));
    } catch (_) {
      throw InvitationServiceException('Không thể tải bài tuyển của bạn.');
    }
  }
}

String _mapClientError(ClientException error) {
  if (error.response['message'] is String) {
    return error.response['message'] as String;
  }
  return 'Có lỗi xảy ra. Vui lòng thử lại.';
}

String _escape(String value) => value.replaceAll("'", "\\'");
