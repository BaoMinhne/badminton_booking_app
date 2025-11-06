import 'package:flutter/foundation.dart';

import '../../../models/booked_court_option.dart';
import '../../../models/recruitment_post.dart';
import '../../../services/booking_service.dart';
import '../../../services/recruitment_service.dart';

class RecruitmentFormManager with ChangeNotifier {
  RecruitmentFormManager({
    BookingService? bookingService,
    RecruitmentService? recruitmentService,
  })  : _bookingService = bookingService ?? BookingService(),
        _recruitmentService = recruitmentService ?? RecruitmentService();

  final BookingService _bookingService;
  final RecruitmentService _recruitmentService;

  bool _hasBookedCourt = true;
  bool _isCheckingBookings = false;
  bool _isSubmitting = false;
  DateTime _selectedDateTime =
      DateTime.now().add(const Duration(hours: 2)).toLocal();
  List<BookedCourtOption> _availableBookings = const [];
  BookedCourtOption? _selectedBooking;
  String? _bookingMessage;

  bool get hasBookedCourt => _hasBookedCourt;
  bool get isCheckingBookings => _isCheckingBookings;
  bool get isSubmitting => _isSubmitting;
  DateTime get selectedDateTime => _selectedDateTime;
  List<BookedCourtOption> get availableBookings => _availableBookings;
  BookedCourtOption? get selectedBooking => _selectedBooking;
  String? get bookingMessage => _bookingMessage;

  Future<void> initialize({
    required bool hasBookedCourt,
    required DateTime initialDateTime,
    required String userId,
  }) async {
    _hasBookedCourt = hasBookedCourt;
    _selectedDateTime = initialDateTime;
    _bookingMessage = null;
    notifyListeners();

    if (_hasBookedCourt) {
      await _loadBookingsForDay(userId: userId);
    }
  }

  Future<void> toggleHasBookedCourt(
    bool value, {
    required String userId,
  }) async {
    if (_hasBookedCourt == value) return;
    _hasBookedCourt = value;
    _bookingMessage = null;
    if (!value) {
      _availableBookings = const [];
      _selectedBooking = null;
      notifyListeners();
      return;
    }
    notifyListeners();
    await _loadBookingsForDay(userId: userId);
  }

  Future<void> setSelectedDateTime(
    DateTime newDateTime, {
    required String userId,
  }) async {
    _selectedDateTime = newDateTime;
    notifyListeners();
    if (_hasBookedCourt) {
      await _loadBookingsForDay(userId: userId);
    }
  }

  void selectBooking(BookedCourtOption? option) {
    _selectedBooking = option;
    notifyListeners();
  }

  Future<RecruitmentPost> submitRecruitmentPost({
    required String authorId,
    required String content,
    required int targetMemberCount,
    String? skillLevel,
    String? playStyle,
    String? locationNote,
    DateTime? expiresAt,
  }) async {
    if (_isSubmitting) {
      throw RecruitmentServiceException('Đang gửi bài, vui lòng chờ.');
    }
    _isSubmitting = true;
    notifyListeners();

    try {
      final courtId = _hasBookedCourt ? _selectedBooking?.courtId : null;
      return await _recruitmentService.createRecruitmentPost(
        authorId: authorId,
        content: content,
        eventTime: _selectedDateTime,
        targetMemberCount: targetMemberCount,
        courtId: courtId,
        skillLevel: skillLevel,
        playStyle: playStyle,
        locationNote: locationNote,
        expiresAt: expiresAt,
      );
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> _loadBookingsForDay({required String userId}) async {
    _isCheckingBookings = true;
    _bookingMessage = null;
    notifyListeners();

    final dayStart = DateTime(
      _selectedDateTime.year,
      _selectedDateTime.month,
      _selectedDateTime.day,
    );
    final dayEnd = dayStart.add(const Duration(days: 1));

    try {
      final bookings = await _bookingService.listUserBookings(
        userId: userId,
        startTimeInclusive: dayStart,
        endTimeExclusive: dayEnd,
      );
      final options = bookings
          .map(BookedCourtOption.fromUserBooking)
          .toList(growable: false);

      _availableBookings = options;
      if (options.isEmpty) {
        _bookingMessage =
            'Bạn chưa có sân nào trong ngày ${dayStart.day}/${dayStart.month}';
        _selectedBooking = null;
      } else {
        _selectedBooking = options.first;
      }
    } catch (error) {
      _bookingMessage = error.toString();
      _availableBookings = const [];
      _selectedBooking = null;
    } finally {
      _isCheckingBookings = false;
      notifyListeners();
    }
  }
}
