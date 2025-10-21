import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../models/booking.dart';
import '../../services/booking_service.dart';
import '../../services/pocketbase_client.dart';

class BookingManager with ChangeNotifier {
  BookingManager({BookingService? bookingService})
      : _bookingService = bookingService ?? BookingService();

  final BookingService _bookingService;

  String? _courtId;
  DateTime _date = DateTime.now();
  String? _currentUserId;
  Duration _slotDuration = const Duration(hours: 1);

  bool _isInitialized = false;
  bool _isLoading = false;
  bool _isMutating = false;
  String? _error;

  List<CourtBooking> _bookings = <CourtBooking>[];
  final Set<SelectedSlot> _selectedSlots = <SelectedSlot>{};
  final Map<String, CourtBooking> _heldByMe = <String, CourtBooking>{};
  final Map<String, SelectedSlot> _heldSlots = <String, SelectedSlot>{};

  RealtimeSubscription? _realtimeSubscription;
  StreamSubscription<RecordSubscriptionEvent>? _rtSub;

  String? get courtId => _courtId;
  DateTime get date => _date;
  String? get currentUserId => _currentUserId;
  Duration get slotDuration => _slotDuration;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  bool get isMutating => _isMutating;
  String? get error => _error;

  List<CourtBooking> get bookings => List.unmodifiable(_bookings);
  Set<SelectedSlot> get selectedSlots => Set.unmodifiable(_selectedSlots);
  Map<String, CourtBooking> get heldByMe => Map.unmodifiable(_heldByMe);
  List<SelectedSlot> get heldSlots {
    final items = _heldSlots.values.toList(growable: false);
    items.sort((a, b) => a.startTime.compareTo(b.startTime));
    return items;
  }

  List<CourtBooking> get heldBookings {
    final map = <String, CourtBooking>{};
    for (final booking in _heldByMe.values) {
      map[booking.id] = booking;
    }
    final items = map.values.toList(growable: false)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    return items;
  }

  Iterable<CourtBooking> get awaitingPaymentBookings {
    if (_currentUserId == null) {
      return const Iterable<CourtBooking>.empty();
    }
    return _bookings.where((booking) =>
        booking.userId == _currentUserId &&
        booking.status == BookingStatus.awaitingPayment);
  }

  DateTime? get holdExpiresAt {
    DateTime? result;
    for (final booking in heldBookings) {
      final locked = booking.lockedUntil;
      if (locked == null) continue;
      if (result == null || locked.isBefore(result)) {
        result = locked;
      }
    }
    return result;
  }

  Future<void> init({
    required String courtId,
    required DateTime date,
    String? userId,
    Duration? slotDuration,
  }) async {
    _courtId = courtId;
    _date = DateTime(date.year, date.month, date.day);
    _currentUserId = userId;
    if (slotDuration != null) {
      _slotDuration = slotDuration;
    }

    _selectedSlots.clear();
    _heldByMe.clear();
    _heldSlots.clear();
    _error = null;
    _isLoading = true;
    _isInitialized = true;
    notifyListeners();

    await _teardownRealtime();

    try {
      await _refreshBookingsInternal();
      await _setupRealtime(courtId);
    } catch (error) {
      _error = _describeError(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> changeDate(DateTime newDate) async {
    if (_courtId == null) return;
    await init(
      courtId: _courtId!,
      date: newDate,
      userId: _currentUserId,
      slotDuration: _slotDuration,
    );
  }

  Future<void> refetch({bool showLoading = false}) async {
    if (_courtId == null) return;
    if (showLoading) {
      _isLoading = true;
      notifyListeners();
    }
    try {
      await _refreshBookingsInternal();
    } catch (error) {
      _error = _describeError(error);
      rethrow;
    } finally {
      if (showLoading) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  void updateSlotDuration(Duration duration) {
    if (duration == _slotDuration) return;
    _slotDuration = duration;
    _rebuildHeldSlots();
    notifyListeners();
  }

  bool isSlotUnavailable(SelectedSlot slot, {String? myUserId}) {
    final canonical = _canonicalize(slot);
    final key = canonical.key;
    if (_heldByMe.containsKey(key)) {
      return true;
    }

    final requesterId = myUserId ?? _currentUserId;
    for (final booking in _bookings) {
      if (booking.courtUnitId != canonical.courtUnitId) continue;
      if (!_isBlockingBooking(booking)) continue;
      if (_overlapsBooking(booking, canonical)) {
        if (requesterId == null) {
          return true;
        }
        if (booking.userId == requesterId) {
          return true;
        }
        return true;
      }
    }
    return false;
  }

  void toggleSelect(SelectedSlot slot) {
    final canonical = _canonicalize(slot);
    if (_selectedSlots.remove(canonical)) {
      notifyListeners();
      return;
    }

    if (isSlotUnavailable(canonical, myUserId: _currentUserId)) {
      return;
    }

    for (final existing in _selectedSlots) {
      if (existing.courtUnitId != canonical.courtUnitId) continue;
      if (_slotsOverlap(existing, canonical)) {
        return;
      }
    }

    _selectedSlots.add(canonical);
    notifyListeners();
  }

  Future<void> holdSelected({required String userId}) async {
    if (_courtId == null) return;
    if (_selectedSlots.isEmpty) return;

    final slots = _selectedSlots.toList(growable: false)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    _isMutating = true;
    notifyListeners();

    try {
      for (final slot in slots) {
        final booking = await _bookingService.lockSlot(
          courtId: _courtId!,
          courtUnitId: slot.courtUnitId,
          userId: userId,
          startTime: slot.startTime.toUtc(),
          endTime: slot.endTime.toUtc(),
        );
        _replaceBooking(booking);
        final key = slot.key;
        _heldByMe[key] = booking;
        _heldSlots[key] = slot;
      }
      _selectedSlots.clear();
    } on BookingServiceException {
      rethrow;
    } catch (error) {
      rethrow;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  Future<void> cancelHold(SelectedSlot slot) async {
    final canonical = _canonicalize(slot);
    final key = canonical.key;
    final booking = _heldByMe[key];

    if (booking == null) {
      if (_selectedSlots.remove(canonical)) {
        notifyListeners();
      }
      return;
    }

    _isMutating = true;
    notifyListeners();

    try {
      await _bookingService.releaseBooking(booking.id);
      _removeHeldBookingById(booking.id);
      _bookings.removeWhere((element) => element.id == booking.id);
    } on BookingServiceException {
      rethrow;
    } catch (error) {
      rethrow;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  Future<void> proceedToPayment() async {
    final toUpdate = heldBookings;
    if (toUpdate.isEmpty) return;

    _isMutating = true;
    notifyListeners();

    try {
      for (final booking in toUpdate) {
        final updated = await _bookingService.submitForApproval(booking.id);
        _replaceBooking(updated);
        _removeHeldBookingById(updated.id);
      }
    } on BookingServiceException {
      rethrow;
    } catch (error) {
      rethrow;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  Future<void> confirmAllAfterPayment() async {
    if (_currentUserId == null) return;
    final awaiting = _bookings
        .where((booking) =>
            booking.userId == _currentUserId &&
            booking.status == BookingStatus.awaitingPayment)
        .toList(growable: false);
    if (awaiting.isEmpty) return;

    _isMutating = true;
    notifyListeners();

    try {
      for (final booking in awaiting) {
        final updated = await _bookingService.markAsConfirmed(booking.id);
        _replaceBooking(updated);
      }
    } on BookingServiceException {
      rethrow;
    } catch (error) {
      rethrow;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    unawaited(_teardownRealtime());
    super.dispose();
  }

  Future<void> _refreshBookingsInternal() async {
    if (_courtId == null) return;
    final bookings = await _bookingService.listBookings(
      courtId: _courtId!,
      date: _date,
    );
    bookings.sort((a, b) => a.startTime.compareTo(b.startTime));
    _bookings = bookings;
    _rebuildHeldSlots();
  }

  void _replaceBooking(CourtBooking booking) {
    final index = _bookings.indexWhere((item) => item.id == booking.id);
    if (index >= 0) {
      _bookings[index] = booking;
    } else {
      _bookings.add(booking);
    }
    _bookings.sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  void _rebuildHeldSlots() {
    _heldByMe.clear();
    _heldSlots.clear();
    if (_currentUserId == null) return;
    for (final booking in _bookings) {
      if (booking.userId != _currentUserId) continue;
      if (booking.status != BookingStatus.held) continue;
      if (!booking.isActiveLock) continue;
      for (final slot in booking.splitToSlots(_slotDuration)) {
        final canonical = _canonicalize(slot);
        final key = canonical.key;
        _heldByMe[key] = booking;
        _heldSlots[key] = canonical;
      }
    }
  }

  bool _isBlockingBooking(CourtBooking booking) {
    switch (booking.status) {
      case BookingStatus.held:
        return booking.isActiveLock;
      case BookingStatus.awaitingPayment:
      case BookingStatus.confirmed:
        return true;
      case BookingStatus.cancelled:
      case BookingStatus.expired:
        return false;
    }
  }

  bool _overlapsBooking(CourtBooking booking, SelectedSlot slot) {
    final bookingStart = booking.startTime.toUtc();
    final bookingEnd = booking.endTime.toUtc();
    return _intervalsOverlap(
      bookingStart,
      bookingEnd,
      slot.startTime.toUtc(),
      slot.endTime.toUtc(),
    );
  }

  bool _slotsOverlap(SelectedSlot a, SelectedSlot b) {
    return _intervalsOverlap(
      a.startTime.toUtc(),
      a.endTime.toUtc(),
      b.startTime.toUtc(),
      b.endTime.toUtc(),
    );
  }

  bool _intervalsOverlap(
    DateTime startA,
    DateTime endA,
    DateTime startB,
    DateTime endB,
  ) {
    return startA.isBefore(endB) && startB.isBefore(endA);
  }

  SelectedSlot _canonicalize(SelectedSlot slot) {
    return SelectedSlot(
      courtUnitId: slot.courtUnitId,
      startTime: slot.startTime.toUtc(),
      endTime: slot.endTime.toUtc(),
    );
  }

  void _removeHeldBookingById(String bookingId) {
    final keysToRemove = _heldByMe.entries
        .where((entry) => entry.value.id == bookingId)
        .map((entry) => entry.key)
        .toList(growable: false);
    for (final key in keysToRemove) {
      _heldByMe.remove(key);
      _heldSlots.remove(key);
    }
  }

  Future<void> _setupRealtime(String courtId) async {
    try {
      final pb = await getPocketbaseInstance();
      _realtimeSubscription =
          await pb.collection(BookingService.collection).subscribe('*');
      _rtSub = _realtimeSubscription?.stream.listen((event) {
        final record = event.record;
        if (record != null) {
          final recordCourtId = (record.data['court_id'] as String?) ?? '';
          if (recordCourtId != _courtId) {
            return;
          }
        }
        // ignore errors – background refresh only
        _refreshBookingsInternal().then((_) {
          notifyListeners();
        }).catchError((_) {});
      });
    } catch (_) {
      // Realtime not critical; ignore errors silently.
    }
  }

  Future<void> _teardownRealtime() async {
    await _rtSub?.cancel();
    _rtSub = null;
    if (_realtimeSubscription != null) {
      try {
        final pb = await getPocketbaseInstance();
        await pb
            .collection(BookingService.collection)
            .unsubscribe(_realtimeSubscription!);
      } catch (_) {
        // ignore
      }
      _realtimeSubscription = null;
    }
  }

  String _describeError(Object error) {
    if (error is BookingServiceException) {
      return error.message;
    }
    return 'Đã xảy ra lỗi. Vui lòng thử lại.';
  }
}
