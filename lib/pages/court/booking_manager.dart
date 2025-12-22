import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:badminton_booking_app/models/booking.dart';
import 'package:badminton_booking_app/models/court_detail.dart';
import 'package:badminton_booking_app/services/booking_realtime_service.dart';
import 'package:badminton_booking_app/services/booking_service.dart';
import 'package:badminton_booking_app/utils/booking_helpers.dart';
import 'package:badminton_booking_app/services/payment_service.dart';

class BookingManager extends ChangeNotifier {
  static const Duration _awaitingPaymentTimeout = Duration(minutes: 15);

  BookingManager({
    required this.detailData,
    BookingService? bookingService,
    PaymentService? paymentService,
    this.slotDuration = const Duration(hours: 1),
    this.unitGroupSize = 5,
  })  : assert(unitGroupSize > 0, 'unitGroupSize must be positive'),
        _bookingService = bookingService ?? BookingService(),
        _paymentService = paymentService ?? PaymentService() {
    _selectedDate = _normalizeDate(DateTime.now());

    Future.microtask(() => loadBookings());
  }

  final CourtDetailData detailData;
  final Duration slotDuration;
  final int unitGroupSize;
  final BookingService _bookingService;
  final PaymentService _paymentService;
  final BookingRealtimeService _realtimeService = BookingRealtimeService();

  DateTime _selectedDate = DateTime.now();
  int _selectedUnitGroupIndex = 0;
  String? _currentUserId;

  bool _isLoading = false;
  bool _isSubmittingHeldBookings = false;
  bool _isConfirmingPayment = false;

  String? _friendlyErrorMessage;

  List<CourtBooking> _loadedBookings = <CourtBooking>[];
  final Set<SelectedSlot> _selectedSlots = <SelectedSlot>{};
  final Map<SelectedSlot, CourtBooking> _heldBookingsBySlot =
      <SelectedSlot, CourtBooking>{};
  final Set<SelectedSlot> _slotsInProgress = <SelectedSlot>{};

  final Map<String, _BookingCacheEntry> _bookingCacheByKey =
      <String, _BookingCacheEntry>{};

  @override
  void dispose() {
    _realtimeService.dispose();
    super.dispose();
  }

  DateTime get selectedDate => _selectedDate;
  int get selectedUnitGroupIndex => _selectedUnitGroupIndex;
  bool get isLoading => _isLoading;
  bool get isSubmittingHeldBookings => _isSubmittingHeldBookings;
  bool get isConfirmingPayment => _isConfirmingPayment;
  String? get friendlyErrorMessage => _friendlyErrorMessage;
  List<CourtBooking> get bookings => List.unmodifiable(_loadedBookings);
  List<CourtUnit> get activeCourtUnits =>
      detailData.units.where((unit) => unit.isActive).toList(growable: false);
  List<CourtUnit> get visibleCourtUnits {
    final units = activeCourtUnits;
    if (units.isEmpty) {
      return const [];
    }
    final totalGroups = totalCourtUnitGroups;
    if (totalGroups == 0) {
      return const [];
    }
    final safeIndex = _selectedUnitGroupIndex.clamp(0, totalGroups - 1).toInt();
    final start = safeIndex * unitGroupSize;
    final end = math.min(start + unitGroupSize, units.length);
    return units.sublist(start, end);
  }

  int get totalCourtUnitGroups {
    final units = activeCourtUnits;
    if (units.isEmpty) {
      return 0;
    }
    return (units.length / unitGroupSize).ceil();
  }

  List<CourtBooking> get bookingsForVisibleUnits {
    final visibleUnits = visibleCourtUnits;
    if (visibleUnits.isEmpty) {
      return List.unmodifiable(_loadedBookings);
    }
    final visibleIds = visibleUnits.map((unit) => unit.id).toSet();
    return List.unmodifiable(
      _loadedBookings
          .where((booking) => visibleIds.contains(booking.courtUnitId)),
    );
  }

  Set<SelectedSlot> get selectedSlots => Set.unmodifiable(_selectedSlots);
  Iterable<CourtBooking> get heldBookings => _heldBookingsBySlot.values;
  Iterable<CourtBooking> get awaitingPaymentBookings =>
      _loadedBookings.where(_isAwaitingPaymentAndMine);

  bool get hasHeldBookings => _heldBookingsBySlot.isNotEmpty;
  bool get hasAwaitingPaymentBookings => awaitingPaymentBookings.isNotEmpty;

  Duration get totalSelectedDuration {
    var totalMinutes = 0;
    for (final slot in _selectedSlots) {
      totalMinutes += slot.endTime.difference(slot.startTime).inMinutes;
    }
    return Duration(minutes: totalMinutes);
  }

  double get totalSelectedPrice {
    var totalPrice = 0.0;
    for (final slot in _selectedSlots) {
      totalPrice += calculateSlotPrice(detailData, slot, slotDuration);
    }
    return totalPrice;
  }

  DateTime? get holdExpiresAt {
    DateTime? result;
    for (final booking in _heldBookingsBySlot.values) {
      final locked = booking.lockedUntil?.toLocal();
      if (locked == null) {
        continue;
      }
      if (result == null || locked.isBefore(result)) {
        result = locked;
      }
    }
    return result;
  }

  void updateCurrentUser(String? userId) {
    if (userId == _currentUserId) {
      return;
    }
    _currentUserId = userId;
    _syncSelectedSlotsWithBookings();
    notifyListeners();
    unawaited(loadBookings(forceRefresh: true));
  }

  Future<void> changeDate(DateTime date) async {
    final normalized = _normalizeDate(date);
    if (normalized.isAtSameMomentAs(_selectedDate)) {
      return;
    }
    _selectedDate = normalized;
    _friendlyErrorMessage = null;
    notifyListeners();
    await loadBookings();
  }

  Future<void> changeCourtUnitGroup(int groupIndex) async {
    final totalGroups = totalCourtUnitGroups;
    if (totalGroups == 0) {
      return;
    }
    final clampedIndex = groupIndex.clamp(0, totalGroups - 1).toInt();
    if (clampedIndex == _selectedUnitGroupIndex) {
      return;
    }
    _selectedUnitGroupIndex = clampedIndex;
    notifyListeners();
  }

  Future<void> loadBookings({bool forceRefresh = false}) async {
    final cacheKey = _cacheKeyFor(_selectedDate, null);

    if (!forceRefresh) {
      final cached = _bookingCacheByKey[cacheKey];
      if (cached != null) {
        _loadedBookings = List<CourtBooking>.from(cached.bookings);
        _friendlyErrorMessage = null;
        _syncSelectedSlotsWithBookings();
        notifyListeners();
        return;
      }
    }

    _isLoading = true;
    _friendlyErrorMessage = null;
    notifyListeners();

    try {
      final bookings = await _bookingService.listBookings(
        courtId: detailData.court.id,
        date: _selectedDate,
      );
      _loadedBookings = await _expireOverdueAwaitingPayments(bookings);
      _updateCache(_loadedBookings, _selectedDate);
      _syncSelectedSlotsWithBookings();
      _isLoading = false;
      notifyListeners();
      unawaited(_subscribeToRealtime());
    } catch (error) {
      _isLoading = false;
      _friendlyErrorMessage = _describeFriendlyError(error);
      notifyListeners();
    }
  }

  Future<List<CourtBooking>> _expireOverdueAwaitingPayments(
    List<CourtBooking> bookings,
  ) async {
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      return bookings;
    }
    final now = DateTime.now().toUtc();
    final expiryThreshold = now.subtract(_awaitingPaymentTimeout);
    final overdue = bookings.where((booking) {
      return booking.status == BookingStatus.awaitingPayment &&
          booking.userId == _currentUserId &&
          booking.updatedAt.isBefore(expiryThreshold);
    }).toList(growable: false);

    if (overdue.isEmpty) {
      return bookings;
    }

    final updated = List<CourtBooking>.from(bookings);
    for (final booking in overdue) {
      try {
        final expired = await _bookingService.markAsExpired(booking.id);
        final index = updated.indexWhere((item) => item.id == booking.id);
        if (index >= 0) {
          updated[index] = expired;
        }
      } catch (_) {
        // Ignore failures and keep existing status.
      }
    }
    return updated;
  }

  Future<void> refreshBookings() => loadBookings(forceRefresh: true);

  Future<void> _subscribeToRealtime() async {
    await _realtimeService.subscribeToBookings(
      courtId: detailData.court.id,
      date: _selectedDate,
      onChange: _handleRealtimeEvent,
    );
  }

  void _handleRealtimeEvent(RecordSubscriptionEvent event) {
    final record = event.record;
    if (record == null) return;

    final incoming = CourtBooking.fromRecord(record);
    final updated = List<CourtBooking>.from(_loadedBookings);

    switch (event.action) {
      case 'delete':
        updated.removeWhere((item) => item.id == incoming.id);
        break;
      case 'create':
        updated.add(incoming);
        break;
      case 'update':
        final index = updated.indexWhere((item) => item.id == incoming.id);
        if (index >= 0) {
          updated[index] = incoming;
        } else {
          updated.add(incoming);
        }
        break;
      default:
        return;
    }

    _loadedBookings = updated;
    _updateCache(_loadedBookings, _selectedDate);
    _syncSelectedSlotsWithBookings();
    notifyListeners();
  }

  Future<void> holdSlot(SelectedSlot slot) async {
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      throw BookingManagerException('Vui lòng đăng nhập để giữ chỗ.');
    }

    final normalized = _normalizeSlot(slot);
    if (_slotsInProgress.contains(normalized)) {
      return;
    }
    _slotsInProgress.add(normalized);
    notifyListeners();

    try {
      final booking = await _bookingService.lockSlot(
        courtId: detailData.court.id,
        courtUnitId: normalized.courtUnitId,
        userId: _currentUserId!,
        startTime: normalized.startTime,
        endTime: normalized.endTime,
      );

      _loadedBookings = List<CourtBooking>.from(_loadedBookings)..add(booking);
      _updateCache(_loadedBookings, _selectedDate);
      _selectedSlots.add(normalized);
      _heldBookingsBySlot[normalized] = booking;
      notifyListeners();
    } catch (error) {
      _slotsInProgress.remove(normalized);
      notifyListeners();
      throw BookingManagerException(_describeHoldError(error));
    } finally {
      _slotsInProgress.remove(normalized);
      notifyListeners();
    }
  }

  Future<void> releaseSlot(SelectedSlot slot) async {
    final normalized = _normalizeSlot(slot);
    if (_slotsInProgress.contains(normalized)) {
      return;
    }

    final heldBooking = _heldBookingsBySlot.remove(normalized);
    _selectedSlots.remove(normalized);
    if (heldBooking == null) {
      notifyListeners();
      return;
    }

    _slotsInProgress.add(normalized);
    notifyListeners();

    try {
      await _bookingService.releaseBooking(heldBooking.id);
      _loadedBookings = List<CourtBooking>.from(_loadedBookings)
        ..removeWhere((item) => item.id == heldBooking.id);
      _updateCache(_loadedBookings, _selectedDate);
      notifyListeners();
    } catch (error) {
      _selectedSlots.add(normalized);
      _heldBookingsBySlot[normalized] = heldBooking;
      _slotsInProgress.remove(normalized);
      notifyListeners();
      throw BookingManagerException(_describeFriendlyError(error));
    } finally {
      _slotsInProgress.remove(normalized);
      notifyListeners();
    }
  }

  bool isSlotInProgress(SelectedSlot slot) {
    final normalized = _normalizeSlot(slot);
    return _slotsInProgress.contains(normalized);
  }

  Future<void> submitHeldBookings() async {
    if (_heldBookingsBySlot.isEmpty) return;

    _isSubmittingHeldBookings = true;
    notifyListeners();

    // ✅ LẤY SNAPSHOT TRƯỚC KHI BẮT ĐẦU, TRÁNH BỊ REALTIME LÀM THAY ĐỔI MAP
    final bookingsToSubmit = _heldBookingsBySlot.values.toList(growable: false);

    final updatedBookings = <CourtBooking>[];
    final processedBookingIds = <String>{};

    try {
      // 1) Cập nhật trạng thái trên server
      for (final booking in bookingsToSubmit) {
        if (processedBookingIds.contains(booking.id)) continue;
        final updated = await _bookingService.submitForApproval(booking.id);
        processedBookingIds.add(booking.id);
        updatedBookings.add(updated);
      }

      // 2) Cập nhật lại list local
      final updatedList = List<CourtBooking>.from(_loadedBookings);
      for (final updated in updatedBookings) {
        final index = updatedList.indexWhere((b) => b.id == updated.id);
        if (index != -1) {
          updatedList[index] = updated;
        } else {
          updatedList.add(updated);
        }
      }

      _loadedBookings = updatedList;
      _updateCache(_loadedBookings, _selectedDate);

      // Sau khi submit xong, mình chủ động clear lựa chọn hiện tại
      _heldBookingsBySlot.clear();
      _selectedSlots.clear();
      notifyListeners();

      // 3) Refresh lại ngầm, nếu lỗi thì log nhưng KHÔNG báo lỗi cho user
      unawaited(
        loadBookings(forceRefresh: true).catchError((error, stack) {
          if (kDebugMode) {
            print('loadBookings after submitHeldBookings failed: $error');
          }
        }),
      );
    } on BookingServiceException catch (error) {
      throw BookingManagerException(error.message);
    } finally {
      _isSubmittingHeldBookings = false;
      notifyListeners();
    }
  }

  Future<void> confirmPaymentBookings({
    String provider = 'manual',
    String status = 'succeeded',
    String? transactionRef,
  }) async {
    final bookingsToConfirm = awaitingPaymentBookings.toList();
    if (bookingsToConfirm.isEmpty) {
      return;
    }

    _isConfirmingPayment = true;
    notifyListeners();

    final confirmedBookings = <CourtBooking>[];
    final failedBookings = <CourtBooking>[];

    try {
      for (final booking in bookingsToConfirm) {
        String? paymentId;
        try {
          final amountMinor = _calculateBookingAmount(booking);
          final payment = await _paymentService.createPayment(
            bookingId: booking.id,
            amountMinor: amountMinor,
            currency: 'VND',
            provider: provider,
            status: status,
            transactionRef: transactionRef,
          );
          paymentId = payment.id;

          final updated = await _bookingService.markAsConfirmed(booking.id);
          confirmedBookings.add(updated);
        } catch (_) {
          if (paymentId != null) {
            unawaited(_paymentService.deletePayment(paymentId!).catchError((_) {}));
          }
          failedBookings.add(booking);
        }
      }

      if (failedBookings.isNotEmpty) {
        await loadBookings(forceRefresh: true);
        throw BookingManagerException(
          'Một số lượt đặt đã không thể xác nhận. Vui lòng tải lại và thử lại.',
        );
      }

      final updatedList = List<CourtBooking>.from(_loadedBookings);
      for (final updated in confirmedBookings) {
        final index = updatedList.indexWhere((item) => item.id == updated.id);
        if (index >= 0) {
          updatedList[index] = updated;
        }
      }

      _loadedBookings = updatedList;
      _updateCache(_loadedBookings, _selectedDate);
      notifyListeners();
      await loadBookings(forceRefresh: true);
    } finally {
      _isConfirmingPayment = false;
      notifyListeners();
    }
  }

  int _calculateBookingAmount(CourtBooking booking) {
    final slots = booking.splitToSlots(slotDuration);
    var total = 0.0;
    for (final slot in slots) {
      total += calculateSlotPrice(detailData, slot, slotDuration);
    }
    return total.round();
  }

  int calculateTotalAmount(List<CourtBooking> bookings) {
    var total = 0;
    for (final booking in bookings) {
      total += _calculateBookingAmount(booking);
    }
    return total;
  }

  int calculateBookingAmount(CourtBooking booking) {
    return _calculateBookingAmount(booking);
  }

  Future<void> cancelAwaitingPaymentBookings() async {
    final bookingsToCancel = awaitingPaymentBookings.toList();
    if (bookingsToCancel.isEmpty) {
      return;
    }

    for (final booking in bookingsToCancel) {
      try {
        await _bookingService.cancelBooking(booking.id);
      } catch (_) {
        // swallow errors to avoid blocking cancellation
      }
    }

    await loadBookings(forceRefresh: true);
  }

  bool _isAwaitingPaymentAndMine(CourtBooking booking) {
    if (booking.status != BookingStatus.awaitingPayment) {
      return false;
    }
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      return false;
    }
    return booking.userId == _currentUserId;
  }

  SelectedSlot _normalizeSlot(SelectedSlot slot) {
    return SelectedSlot(
      courtUnitId: slot.courtUnitId,
      startTime: slot.startTime.toUtc(),
      endTime: slot.endTime.toUtc(),
    );
  }

  void _syncSelectedSlotsWithBookings() {
    if (_currentUserId == null) {
      _selectedSlots.clear();
      _heldBookingsBySlot.clear();
      return;
    }

    final updatedSelected = <SelectedSlot>{};
    final updatedHeld = <SelectedSlot, CourtBooking>{};
    for (final booking in _loadedBookings) {
      if (booking.userId != _currentUserId) {
        continue;
      }
      if (booking.status == BookingStatus.held && booking.isActiveLock) {
        final slots = booking.splitToSlots(slotDuration);
        for (final slot in slots) {
          final normalized = _normalizeSlot(slot);
          updatedSelected.add(normalized);
          updatedHeld[normalized] = booking;
        }
      }
    }

    _selectedSlots
      ..clear()
      ..addAll(updatedSelected);
    _heldBookingsBySlot
      ..clear()
      ..addAll(updatedHeld);
  }

  void _updateCache(List<CourtBooking> bookings, DateTime date) {
    final normalizedDate = _normalizeDate(date);
    final baseKey = _cacheKeyFor(normalizedDate, null);
    _bookingCacheByKey[baseKey] = _BookingCacheEntry(
      bookings: List<CourtBooking>.from(bookings),
      fetchedAt: DateTime.now(),
    );

    final grouped = <String, List<CourtBooking>>{};
    for (final booking in bookings) {
      grouped
          .putIfAbsent(booking.courtUnitId, () => <CourtBooking>[])
          .add(booking);
    }

    for (final entry in grouped.entries) {
      final unitKey = _cacheKeyFor(normalizedDate, entry.key);
      _bookingCacheByKey[unitKey] = _BookingCacheEntry(
        bookings: List<CourtBooking>.from(entry.value),
        fetchedAt: DateTime.now(),
      );
    }
  }

  String _cacheKeyFor(DateTime date, String? unitId) {
    final formatter = DateFormat('yyyy-MM-dd');
    final dayLabel = formatter.format(date);
    return '${detailData.court.id}__${dayLabel}__${unitId ?? 'all'}';
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  String _describeFriendlyError(Object error) {
    if (error is BookingServiceException) {
      return error.message;
    }
    return 'Đã xảy ra lỗi. Vui lòng thử lại.';
  }

  String _describeHoldError(Object error) {
    if (error is BookingServiceException) {
      if (error.message.contains('đã có lượt đặt')) {
        return 'Khung giờ vừa chọn đã có người giữ/đặt, vui lòng chọn khung khác.';
      }
      return error.message;
    }
    return 'Không thể giữ chỗ. Vui lòng thử lại.';
  }
}

class _BookingCacheEntry {
  _BookingCacheEntry({
    required this.bookings,
    required this.fetchedAt,
  });

  final List<CourtBooking> bookings;
  final DateTime fetchedAt;
}

class BookingManagerException implements Exception {
  BookingManagerException(this.message);
  final String message;

  @override
  String toString() => message;
}
