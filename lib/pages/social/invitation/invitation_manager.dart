import 'package:flutter/foundation.dart';

import '../../../models/court.dart';
import '../../../models/invitation.dart';
import '../../../models/recruitment_post.dart';
import '../../../models/user_booking_view.dart';
import '../../../services/invitation_service.dart';

class InvitationManager extends ChangeNotifier {
  InvitationManager({InvitationService? service})
      : _service = service ?? InvitationService();

  final InvitationService _service;
  bool _isDisposed = false;

  List<Invitation> _invitations = const <Invitation>[];
  bool _isLoading = false;
  String? _error;

  List<Invitation> get invitations => _invitations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> refreshIncoming() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    _notifyListeners();

    try {
      _invitations = await _service.fetchIncoming();
    } catch (err) {
      _error = err.toString();
    } finally {
      _isLoading = false;
      _notifyListeners();
    }
  }

  Future<void> respond(Invitation invitation, {required bool accept}) async {
    try {
      final updated = await _service.respond(invitation: invitation, accept: accept);
      _invitations = _invitations
          .map((item) => item.id == invitation.id ? updated : item)
          .toList(growable: false);
    } catch (err) {
      _error = err.toString();
    } finally {
      _notifyListeners();
    }
  }

  Future<InvitationComposerData> loadComposerData() {
    return _service.loadComposerData();
  }

  Future<Invitation> sendRecruitmentInvite({
    required String toUserId,
    required String recruitmentId,
    String? message,
  }) async {
    final invitation = await _service.sendRecruitmentInvite(
      toUserId: toUserId,
      recruitmentId: recruitmentId,
      message: message,
    );
    await refreshIncoming();
    return invitation;
  }

  Future<Invitation> sendBookingInvite({
    required String toUserId,
    required UserBookingView booking,
    String? message,
  }) async {
    final invitation = await _service.sendBookingInvite(
      toUserId: toUserId,
      booking: booking,
      message: message,
    );
    await refreshIncoming();
    return invitation;
  }

  Future<Invitation> sendProposedInvite({
    required String toUserId,
    required DateTime startTime,
    DateTime? endTime,
    String? courtId,
    String? message,
  }) async {
    final invitation = await _service.sendProposedInvite(
      toUserId: toUserId,
      startTime: startTime,
      endTime: endTime,
      courtId: courtId,
      message: message,
    );
    await refreshIncoming();
    return invitation;
  }

  List<Court> mapCourts(List<Court> courts) => courts;
  List<RecruitmentPost> mapRecruitments(List<RecruitmentPost> posts) => posts;
  List<UserBookingView> mapBookings(List<UserBookingView> bookings) => bookings;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _notifyListeners() {
    if (_isDisposed) return;
    notifyListeners();
  }
}
