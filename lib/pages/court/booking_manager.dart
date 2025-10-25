import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'package:badminton_booking_app/models/booking.dart';
import 'package:badminton_booking_app/models/court_detail.dart';
import 'package:badminton_booking_app/services/booking_service.dart';
import 'package:badminton_booking_app/utils/booking_helpers.dart';

class BookingManager extends ChangeNotifier {
  BookingManager({
    required this.detailData,
    BookingService? bookingService,
    this.slotDuration = const Duration(hours: 1),
    this.unitGroupSize = 5,
  })  : assert(unitGroupSize > 0, 'unitGroupSize must be positive'),
        _bookingService = bookingService ?? BookingService() {
    _selectedDate = _normalizeDate(DateTime.now());

    Future.microtask(() => loadBookings());
  }

  final CourtDetailData detailData;
  final Duration slotDuration;
  final int unitGroupSize;
  final BookingService _bookingService;

  DateTime _selectedDate = DateTime.now();
  int _selectedUnitGroupIndex = 0;
  String? _currentUserId;

  bool _isLoading = false;
  bool _isSubmittingHeldBookings = false;
  bool _isConfirmingAwaitingPaymentBookings = false;

  String? _friendlyErrorMessage;

  List<CourtBooking> _loadedBookings = <CourtBooking>[];
  final Set<SelectedSlot> _selectedSlots = <SelectedSlot>{};
  final Map<SelectedSlot, CourtBooking> _heldBookingsBySlot =
      <SelectedSlot, CourtBooking>{};
  final Set<SelectedSlot> _slotsInProgress = <SelectedSlot>{};

  final Map<String, _BookingCacheEntry> _bookingCacheByKey =
      <String, _BookingCacheEntry>{};

  DateTime get selectedDate => _selectedDate;
  int get selectedUnitGroupIndex => _selectedUnitGroupIndex;
  bool get isLoading => _isLoading;
  bool get isSubmittingHeldBookings => _isSubmittingHeldBookings;
  bool get isConfirmingAwaitingPayment => _isConfirmingAwaitingPaymentBookings;
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
    final safeIndex =
        _selectedUnitGroupIndex.clamp(0, totalGroups - 1).toInt();
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
      _loadedBookings.where((booking) => visibleIds.contains(booking.courtUnitId)),
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
      _loadedBookings = bookings;
      _updateCache(bookings, _selectedDate);
      _syncSelectedSlotsWithBookings();
      _isLoading = false;
      notifyListeners();
    } catch (error) {
      _isLoading = false;
      _friendlyErrorMessage = _describeFriendlyError(error);
      notifyListeners();
    }
  }

  Future<void> refreshBookings() => loadBookings(forceRefresh: true);

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

  Future<void> submitHeldBookingsForPayment() async {
    if (_heldBookingsBySlot.isEmpty) {
      return;
    }

    _isSubmittingHeldBookings = true;
    notifyListeners();

    try {
      final updatedBookings = <CourtBooking>[];
      final processedBookingIds = <String>{};
      for (final booking in _heldBookingsBySlot.values) {
        if (processedBookingIds.contains(booking.id)) {
          continue;
        }
        final updated = await _bookingService.submitForApproval(booking.id);
        processedBookingIds.add(booking.id);
        updatedBookings.add(updated);
      }

      final updatedList = List<CourtBooking>.from(_loadedBookings);
      for (final updated in updatedBookings) {
        final index = updatedList.indexWhere((item) => item.id == updated.id);
        if (index >= 0) {
          updatedList[index] = updated;
        }
      }

      _loadedBookings = updatedList;
      _updateCache(_loadedBookings, _selectedDate);
      _heldBookingsBySlot.clear();
      _selectedSlots.clear();
      notifyListeners();
      await loadBookings(forceRefresh: true);
    } catch (error) {
      _isSubmittingHeldBookings = false;
      notifyListeners();
      throw BookingManagerException(_describeFriendlyError(error));
    } finally {
      _isSubmittingHeldBookings = false;
      notifyListeners();
    }
  }

  Future<void> confirmAwaitingPaymentBookings() async {
    final bookingsToConfirm = awaitingPaymentBookings.toList();
    if (bookingsToConfirm.isEmpty) {
      return;
    }

    _isConfirmingAwaitingPaymentBookings = true;
    notifyListeners();

    final confirmedBookings = <CourtBooking>[];
    final failedBookings = <CourtBooking>[];

    try {
      for (final booking in bookingsToConfirm) {
        try {
          final updated = await _bookingService.markAsConfirmed(booking.id);
          confirmedBookings.add(updated);
        } catch (_) {
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
      _isConfirmingAwaitingPaymentBookings = false;
      notifyListeners();
    }
  }

  Future<void> cancelHeldBookings() async {
    if (_heldBookingsBySlot.isEmpty) {
      _selectedSlots.clear();
      notifyListeners();
      return;
    }

    final bookingsToCancel = _heldBookingsBySlot.values.toList();
    _heldBookingsBySlot.clear();
    _selectedSlots.clear();
    notifyListeners();

    for (final booking in bookingsToCancel) {
      try {
        await _bookingService.releaseBooking(booking.id);
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
