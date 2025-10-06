import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:badminton_booking_app/components/my_court_time.dart';
import 'package:badminton_booking_app/models/court.dart';
import 'package:badminton_booking_app/models/court_booking.dart';
import 'package:badminton_booking_app/models/court_detail.dart';
import 'package:badminton_booking_app/services/booking_service.dart';
import 'package:badminton_booking_app/services/court_service.dart';

class BookingPage extends StatefulWidget {
  const BookingPage({
    super.key,
    required this.court,
    this.courtService,
    this.bookingService,
  });

  final Court court;
  final CourtService? courtService;
  final BookingService? bookingService;

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  late final CourtService _courtService;
  late final BookingService _bookingService;

  DateTime _selectedDate = _normalizeDate(DateTime.now());
  CourtDetailData? _detailData;
  bool _isLoadingDetail = false;
  bool _isLoadingBookings = false;
  bool _isSubmitting = false;
  String? _detailError;
  String? _bookingError;
  final List<CourtBooking> _bookings = [];

  String? _selectedUnitId;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final TextEditingController _noteController = TextEditingController();
  CourtBooking? _activeLock;
  Duration? _lockRemaining;
  Timer? _lockTimer;
  bool _isLockingSlot = false;

  @override
  void initState() {
    super.initState();
    _courtService = widget.courtService ?? CourtService();
    _bookingService = widget.bookingService ?? BookingService();
    _loadDetail();
  }

  @override
  void dispose() {
    _cancelLockTimer();
    final lock = _activeLock;
    if (lock != null && lock.status == CourtBookingStatus.locked) {
      _bookingService.cancelBooking(lock.id).catchError((_) {});
    }
    _noteController.dispose();
    super.dispose();
  }

  static DateTime _normalizeDate(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static const Duration _defaultSelectionDuration = Duration(hours: 1);
  static const Duration _minimumBookingDuration = Duration(minutes: 30);

  Duration get _currentSelectionDuration {
    if (_startTime == null || _endTime == null) {
      return _defaultSelectionDuration;
    }
    final start = _combine(_selectedDate, _startTime!);
    final end = _combine(_selectedDate, _endTime!);
    final diff = end.difference(start);
    if (diff < _minimumBookingDuration) {
      return _defaultSelectionDuration;
    }
    return diff;
  }

  void _cancelLockTimer() {
    _lockTimer?.cancel();
    _lockTimer = null;
  }

  Future<void> _releaseActiveLock({
    bool notifyServer = false,
    bool clearSelection = false,
  }) async {
    final lock = _activeLock;
    if (lock == null) return;
    _cancelLockTimer();
    if (notifyServer && lock.status.isLocked) {
      try {
        await _bookingService.cancelBooking(lock.id);
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      if (_activeLock?.id == lock.id) {
        _activeLock = null;
        _lockRemaining = null;
        if (clearSelection) {
          _startTime = null;
          _endTime = null;
        }
      }
    });
  }

  void _startLockCountdown(CourtBooking lock) {
    if (!lock.status.isLocked) {
      _cancelLockTimer();
      if (mounted) {
        setState(() => _lockRemaining = null);
      }
      return;
    }

    _cancelLockTimer();
    _updateLockRemaining(lock);
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _updateLockRemaining(lock);
    });
  }

  void _updateLockRemaining(CourtBooking lock) {
    if (!mounted || _activeLock?.id != lock.id) return;
    final remaining = lock.lockRemaining;
    if (remaining == null) {
      _handleLockExpired(lock);
      return;
    }

    setState(() => _lockRemaining = remaining);

    if (remaining <= Duration.zero) {
      _handleLockExpired(lock);
    }
  }

  void _handleLockExpired(CourtBooking lock) {
    if (!mounted || _activeLock?.id != lock.id) return;

    _cancelLockTimer();

    setState(() {
      _activeLock = null;
      _lockRemaining = null;
      _startTime = null;
      _endTime = null;
    });

    _showSnackBar(
      'Phiên giữ chỗ đã hết hạn. Vui lòng chọn lại khung giờ.',
      isError: true,
    );

    () async {
      try {
        await _bookingService.cancelBooking(lock.id);
      } catch (_) {}
      await _loadBookings();
    }();
  }

  void _refreshActiveLockAfterReload(List<CourtBooking> bookings) {
    final lock = _activeLock;
    if (!mounted || lock == null) return;

    CourtBooking? updated;
    for (final booking in bookings) {
      if (booking.id == lock.id) {
        updated = booking;
        break;
      }
    }

    if (updated == null) {
      _cancelLockTimer();
      setState(() {
        if (_activeLock?.id == lock.id) {
          _activeLock = null;
          _lockRemaining = null;
          _startTime = null;
          _endTime = null;
        }
      });
      return;
    }

    setState(() {
      _activeLock = updated;
      _selectedUnitId = updated.courtUnitId;
      _startTime = TimeOfDay.fromDateTime(updated.startTime);
      _endTime = TimeOfDay.fromDateTime(updated.endTime);
    });

    if (updated.status.isLocked && updated.isLocked) {
      _startLockCountdown(updated);
    } else {
      _cancelLockTimer();
      setState(() => _lockRemaining = null);
    }
  }

  void _handleTimelineTap(String unitId, DateTime start) {
    if (_isLockingSlot || _isSubmitting) return;
    _lockSlotForSelection(unitId, start);
  }

  Future<void> _lockSlotForSelection(String unitId, DateTime start) async {
    if (_isLockingSlot) return;

    var end = start.add(_currentSelectionDuration);
    final close = _closingTime;
    if (close != null) {
      final closeDate = _combine(_selectedDate, close);
      if (end.isAfter(closeDate)) {
        end = closeDate;
      }
    }

    if (!end.isAfter(start)) {
      end = start.add(_minimumBookingDuration);
    }

    if (!end.isAfter(start)) {
      _showSnackBar('Không thể giữ chỗ với thời gian quá ngắn.', isError: true);
      return;
    }

    final overlaps = _bookings.any((booking) {
      if (!booking.blocksTime) return false;
      if (booking.courtUnitId != unitId) return false;
      if (_activeLock != null && booking.id == _activeLock!.id) return false;
      return start.isBefore(booking.endTime) && end.isAfter(booking.startTime);
    });

    if (overlaps) {
      _showSnackBar(
        'Khung giờ đã được giữ hoặc đặt. Vui lòng chọn khung giờ khác.',
        isError: true,
      );
      return;
    }

    setState(() => _isLockingSlot = true);

    try {
      final lock = await _bookingService.lockSlot(
        bookingId: _activeLock?.id,
        courtId: widget.court.id,
        courtUnitId: unitId,
        startTime: start,
        endTime: end,
      );

      if (!mounted) return;

      setState(() {
        _activeLock = lock;
        _selectedUnitId = lock.courtUnitId;
        _startTime = TimeOfDay.fromDateTime(lock.startTime);
        _endTime = TimeOfDay.fromDateTime(lock.endTime);
      });

      _startLockCountdown(lock);
      await _loadBookings();
    } catch (error) {
      if (!mounted) return;
      _showSnackBar(
        _describeError(
          error,
          fallback: 'Không thể giữ chỗ. Vui lòng thử lại.',
        ),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isLockingSlot = false);
      }
    }
  }

  Future<void> _cancelHold() async {
    final lock = _activeLock;
    if (lock == null) return;

    setState(() => _isLockingSlot = true);

    try {
      await _bookingService.cancelBooking(lock.id);
      if (!mounted) return;

      _cancelLockTimer();
      setState(() {
        if (_activeLock?.id == lock.id) {
          _activeLock = null;
          _lockRemaining = null;
          _startTime = null;
          _endTime = null;
        }
      });

      await _loadBookings();
      if (mounted) {
        _showSnackBar('Đã huỷ giữ chỗ.');
      }
    } catch (error) {
      if (!mounted) return;
      _showSnackBar(
        _describeError(
          error,
          fallback: 'Không thể huỷ giữ chỗ. Vui lòng thử lại.',
        ),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isLockingSlot = false);
      }
    }
  }

  String _formatCountdown(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    final buffer = StringBuffer();
    if (hours > 0) {
      buffer
        ..write(hours.toString().padLeft(2, '0'))
        ..write(':');
    }
    buffer
      ..write(minutes.toString().padLeft(2, '0'))
      ..write(':')
      ..write(seconds.toString().padLeft(2, '0'));
    return buffer.toString();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoadingDetail = true;
      _detailError = null;
    });

    try {
      final data = await _courtService.getCourtDetail(widget.court.id);
      if (!mounted) return;

      final activeUnits = data.units.where((unit) => unit.isActive).toList();

      setState(() {
        _detailData = data;
        if (_selectedUnitId == null && activeUnits.isNotEmpty) {
          _selectedUnitId = activeUnits.first.id;
        }
        _isLoadingDetail = false;
      });

      await _loadBookings();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _detailError = _describeError(
          error,
          fallback: 'Không thể tải thông tin sân. Vui lòng thử lại.',
        );
        _isLoadingDetail = false;
      });
    }
  }

  Future<void> _loadBookings() async {
    if (_detailError != null) return;

    setState(() {
      _isLoadingBookings = true;
      _bookingError = null;
    });

    try {
      final bookings = await _bookingService.listBookings(
        courtId: widget.court.id,
        day: _selectedDate,
      );

      if (!mounted) return;
      bookings.sort((a, b) => a.startTime.compareTo(b.startTime));

      setState(() {
        _bookings
          ..clear()
          ..addAll(bookings);
        _isLoadingBookings = false;
      });
      _refreshActiveLockAfterReload(bookings);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _bookingError = _describeError(
          error,
          fallback: 'Không thể tải lịch đặt sân. Vui lòng thử lại.',
        );
        _isLoadingBookings = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    if (_detailData == null) {
      await _loadDetail();
    } else {
      await _loadBookings();
    }
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final first = DateTime(now.year, now.month, now.day);
    final last = first.add(const Duration(days: 180));

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: first,
      lastDate: last,
    );

    if (picked != null && picked != _selectedDate) {
      await _releaseActiveLock(notifyServer: true, clearSelection: true);
      setState(() => _selectedDate = _normalizeDate(picked));
      await _loadBookings();
    }
  }

  Future<void> _pickStartTime() async {
    final initial = _startTime ?? _openingStart ?? const TimeOfDay(hour: 6, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );

    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _pickEndTime() async {
    final initial = _endTime ?? _closingTime ?? const TimeOfDay(hour: 8, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );

    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  Future<void> _submitBooking() async {
    if (!_validateBookingInputs()) return;

    final start = _combine(_selectedDate, _startTime!);
    final end = _combine(_selectedDate, _endTime!);
    final note = _noteController.text.trim();

    setState(() => _isSubmitting = true);
    FocusScope.of(context).unfocus();

    try {
      CourtBooking booking;
      final lock = _activeLock;
      if (lock != null && lock.status.isLocked && lock.isLocked) {
        booking = await _bookingService.confirmBooking(
          bookingId: lock.id,
          note: note.isEmpty ? null : note,
        );
      } else {
        booking = await _bookingService.createBooking(
          courtId: widget.court.id,
          courtUnitId: _selectedUnitId!,
          startTime: start,
          endTime: end,
          note: note.isEmpty ? null : note,
        );
      }

      if (!mounted) return;

      _cancelLockTimer();
      setState(() {
        _activeLock = null;
        _lockRemaining = null;
        _startTime = null;
        _endTime = null;
        _noteController.clear();
      });

      final message = booking.status == CourtBookingStatus.confirmed
          ? 'Đặt sân đã được xác nhận.'
          : 'Đã gửi yêu cầu đặt sân. Bạn có thể thanh toán trong lúc chờ quản trị viên duyệt.';
      _showSnackBar(message);

      await _loadBookings();
    } catch (error) {
      if (!mounted) return;
      _showSnackBar(
        _describeError(
          error,
          fallback: 'Không thể gửi yêu cầu đặt sân. Vui lòng thử lại.',
        ),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  bool _validateBookingInputs() {
    final unitId = _selectedUnitId;
    if (unitId == null) {
      _showSnackBar('Vui lòng chọn sân muốn đặt.', isError: true);
      return false;
    }

    if (_startTime == null || _endTime == null) {
      _showSnackBar('Vui lòng chọn thời gian bắt đầu và kết thúc.', isError: true);
      return false;
    }

    final start = _combine(_selectedDate, _startTime!);
    final end = _combine(_selectedDate, _endTime!);

    if (!end.isAfter(start)) {
      _showSnackBar('Giờ kết thúc phải lớn hơn giờ bắt đầu.', isError: true);
      return false;
    }

    final open = _openingStart;
    if (open != null) {
      final openDate = _combine(_selectedDate, open);
      if (start.isBefore(openDate)) {
        _showSnackBar(
          'Sân mở cửa từ ${_formatTimeOfDay(open)}. Vui lòng chọn giờ muộn hơn.',
          isError: true,
        );
        return false;
      }
    }

    final close = _closingTime;
    if (close != null) {
      final closeDate = _combine(_selectedDate, close);
      if (end.isAfter(closeDate)) {
        _showSnackBar(
          'Sân đóng cửa lúc ${_formatTimeOfDay(close)}. Vui lòng điều chỉnh.',
          isError: true,
        );
        return false;
      }
    }

    final overlaps = _bookings.any((booking) {
      if (!booking.blocksTime) return false;
      if (booking.courtUnitId != unitId) return false;
      if (_activeLock != null && booking.id == _activeLock!.id) return false;
      return start.isBefore(booking.endTime) && end.isAfter(booking.startTime);
    });

    if (overlaps) {
      _showSnackBar(
        'Thời gian chọn bị trùng với lịch đã đặt. Vui lòng chọn khung giờ khác.',
        isError: true,
      );
      return false;
    }

    return true;
  }

  void _showSnackBar(String message, {bool isError = false}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
      ),
    );
  }

  List<CourtUnit> get _activeUnits {
    final detail = _detailData;
    if (detail == null) return const [];
    return detail.units.where((unit) => unit.isActive).toList();
  }

  TimeOfDay? get _openingStart {
    final detail = _detailData;
    if (detail == null) return null;
    TimeOfDay? result;
    for (final item in detail.openingHours) {
      final parsed = _parseTimeOfDay(item.openTime);
      if (parsed == null) continue;
      if (result == null || _compareTime(parsed, result) < 0) {
        result = parsed;
      }
    }
    return result;
  }

  TimeOfDay? get _closingTime {
    final detail = _detailData;
    if (detail == null) return null;
    TimeOfDay? result;
    for (final item in detail.openingHours) {
      final parsed = _parseTimeOfDay(item.closeTime);
      if (parsed == null) continue;
      if (result == null || _compareTime(parsed, result) > 0) {
        result = parsed;
      }
    }
    return result;
  }

  int get _timelineStartHour {
    final open = _openingStart;
    if (open == null) return 6;
    return open.hour;
  }

  int get _timelineEndHour {
    final close = _closingTime;
    final start = _timelineStartHour;
    int raw;
    if (close == null) {
      raw = start + 16;
    } else {
      raw = close.minute == 0 ? close.hour : close.hour + 1;
    }
    if (raw <= start) {
      raw = start + 1;
    }
    if (raw > 24) raw = 24;
    return raw;
  }

  List<CourtTimelineEvent> _buildTimelineEvents(ColorScheme cs) {
    final events = <CourtTimelineEvent>[];

    for (final booking in _bookings) {
      if (!booking.blocksTime) continue;
      final isLocked = booking.isLocked;
      final label =
          '${isLocked ? 'Giữ chỗ' : 'Đã đặt'} ${_formatTimeRange(booking.startTime, booking.endTime)}';
      events.add(
        CourtTimelineEvent(
          resourceId: booking.courtUnitId,
          start: booking.startTime,
          end: booking.endTime,
          color: isLocked ? Colors.grey : cs.error,
          textColor: Colors.white,
          label: label,
        ),
      );
    }

    if (_selectedUnitId != null && _startTime != null && _endTime != null) {
      final start = _combine(_selectedDate, _startTime!);
      final end = _combine(_selectedDate, _endTime!);
      if (end.isAfter(start)) {
        events.add(
          CourtTimelineEvent(
            resourceId: _selectedUnitId!,
            start: start,
            end: end,
            color: cs.secondary.withOpacity(0.45),
            borderColor: cs.secondary,
            textColor: cs.onSecondary,
            label: 'Bạn ${_formatTimeRange(start, end)}',
          ),
        );
      }
    }

    return events;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final units = _activeUnits;
    final startHour = _timelineStartHour;
    var endHour = _timelineEndHour;
    if (endHour <= startHour) {
      endHour = startHour + 1;
    }
    final rows = units
        .asMap()
        .entries
        .map(
          (entry) => CourtTimelineRow(
            id: entry.value.id,
            label: entry.value.label.isNotEmpty
                ? entry.value.label
                : 'Sân ${entry.key + 1}',
          ),
        )
        .toList(growable: false);

    final events = _buildTimelineEvents(cs);
    final timelineHeight = (rows.length * 64.0) + 64.0;
    final maxTimelineHeight = MediaQuery.of(context).size.height * 0.6;
    final resolvedHeight = timelineHeight.clamp(200.0, maxTimelineHeight);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt sân'),
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _buildCourtInfoCard(cs),
            const SizedBox(height: 16),
            _buildDateSelector(cs),
            const SizedBox(height: 12),
            _buildLegend(cs),
            const SizedBox(height: 12),
            _buildTimelineCard(
              cs,
              rows,
              events,
              startHour,
              endHour,
              resolvedHeight,
            ),
            const SizedBox(height: 16),
            _buildBookingForm(cs, units),
          ],
        ),
      ),
    );
  }

  Widget _buildCourtInfoCard(ColorScheme cs) {
    final court = widget.court;
    final openingLabel = _buildOpeningLabel();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              court.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.place_outlined, size: 18),
                const SizedBox(width: 6),
                Expanded(child: Text(court.location)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.call, size: 18),
                const SizedBox(width: 6),
                Text(court.phone),
              ],
            ),
            if (openingLabel != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 18),
                  const SizedBox(width: 6),
                  Text(openingLabel),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector(ColorScheme cs) {
    return Card(
      elevation: 2,
      child: ListTile(
        onTap: _isLoadingDetail ? null : _selectDate,
        title: Text(
          'Ngày đặt',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          DateFormat('dd/MM/yyyy').format(_selectedDate),
        ),
        trailing: Icon(Icons.calendar_today, color: cs.primary),
      ),
    );
  }

  Widget _buildLegend(ColorScheme cs) {
    return Row(
      children: [
        _legendTile(color: Colors.white, text: 'Trống', textColor: cs.onSurface),
        const SizedBox(width: 12),
        _legendTile(color: cs.error, text: 'Đã đặt'),
        const SizedBox(width: 12),
        _legendTile(color: Colors.grey, text: 'Giữ chỗ'),
        const SizedBox(width: 12),
        _legendTile(
          color: cs.secondary.withOpacity(0.5),
          borderColor: cs.secondary,
          text: 'Lựa chọn',
          textColor: cs.onSecondary,
        ),
      ],
    );
  }

  Widget _buildTimelineCard(
    ColorScheme cs,
    List<CourtTimelineRow> rows,
    List<CourtTimelineEvent> events,
    int startHour,
    int endHour,
    double height,
  ) {
    if (_detailError != null) {
      return _messageCard(
        icon: Icons.error_outline,
        color: cs.error,
        message: _detailError!,
        action: _loadDetail,
        actionLabel: 'Thử lại',
      );
    }

    if (_isLoadingDetail) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: CircularProgressIndicator(color: cs.primary),
          ),
        ),
      );
    }

    if (rows.isEmpty) {
      return _messageCard(
        icon: Icons.info_outline,
        color: cs.primary,
        message:
            'Sân chưa có danh sách sân con hoạt động. Vui lòng liên hệ quản trị viên.',
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            SizedBox(
              height: height,
              child: Stack(
                children: [
                  CourtTimeline(
                    baseDate: _selectedDate,
                    startHour: startHour,
                    endHour: endHour,
                    rows: rows,
                    events: events,
                    slotWidth: 80,
                    rowHeight: 64,
                    onSlotTap:
                        (_isLoadingBookings || _isLockingSlot) ? null : _handleTimelineTap,
                    selectionStepMinutes: 30,
                  ),
                  if (_isLoadingBookings)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black26,
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),
                  if (_isLockingSlot)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black26,
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (_bookingError != null) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Text(
                      _bookingError!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: cs.error),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: _loadBookings,
                      child: const Text('Tải lại'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBookingForm(ColorScheme cs, List<CourtUnit> units) {
    final isDisabled = _isLoadingDetail || units.isEmpty;
    final activeLock = _activeLock;
    final hasActiveLock =
        activeLock != null && activeLock.status.isLocked && activeLock.isLocked;
    if (units.isEmpty) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Sân chưa có sân con hoạt động để đặt lịch.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
      );
    }
    final dropdownItems = units
        .asMap()
        .entries
        .map(
          (entry) => DropdownMenuItem<String>(
            value: entry.value.id,
            child: Text(entry.value.label.isNotEmpty
                ? entry.value.label
                : 'Sân ${entry.key + 1}'),
          ),
        )
        .toList();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thông tin đặt sân',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (hasActiveLock && activeLock != null) ...[
              _buildActiveLockBanner(cs, activeLock, units),
              const SizedBox(height: 12),
            ],
            DropdownButtonFormField<String>(
              value: dropdownItems.any((item) => item.value == _selectedUnitId)
                  ? _selectedUnitId
                  : (dropdownItems.isNotEmpty ? dropdownItems.first.value : null),
              items: dropdownItems,
              onChanged: (isDisabled || hasActiveLock)
                  ? null
                  : (value) => setState(() => _selectedUnitId = value),
              decoration: const InputDecoration(
                labelText: 'Chọn sân',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _timePickerField(
                    label: 'Giờ bắt đầu',
                    value: _startTime == null ? null : _formatTimeOfDay(_startTime!),
                    onTap:
                        (isDisabled || hasActiveLock) ? null : () => _pickStartTime(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _timePickerField(
                    label: 'Giờ kết thúc',
                    value: _endTime == null ? null : _formatTimeOfDay(_endTime!),
                    onTap:
                        (isDisabled || hasActiveLock) ? null : () => _pickEndTime(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              enabled: !isDisabled,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Ghi chú (tuỳ chọn)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: (isDisabled || _isSubmitting || _isLockingSlot)
                    ? null
                    : () => _submitBooking(),
                icon: _isSubmitting
                    ? SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.onPrimary,
                        ),
                      )
                    : const Icon(Icons.event_available),
                label: Text(_isSubmitting ? 'Đang xử lý...' : 'Đặt sân ngay'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timePickerField({
    required String label,
    required String? value,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          enabled: onTap != null,
        ),
        child: Text(value ?? 'Chọn giờ'),
      ),
    );
  }

  Widget _buildActiveLockBanner(
    ColorScheme cs,
    CourtBooking lock,
    List<CourtUnit> units,
  ) {
    String unitLabel = 'Sân đã chọn';
    for (final unit in units) {
      if (unit.id == lock.courtUnitId) {
        unitLabel = unit.label.isNotEmpty ? unit.label : unitLabel;
        break;
      }
    }

    final range = _formatTimeRange(lock.startTime, lock.endTime);
    final remaining = _lockRemaining ?? lock.lockRemaining;
    final countdown = remaining == null
        ? 'Đang cập nhật...'
        : _formatCountdown(remaining);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_clock, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                'Đang giữ chỗ',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: cs.primary, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                countdown,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: cs.primary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('$unitLabel • $range'),
          const SizedBox(height: 4),
          Text(
            'Nếu muốn đổi khung giờ, chạm lại vào lưới thời gian.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed:
                  (_isLockingSlot || _isSubmitting) ? null : () => _cancelHold(),
              icon: const Icon(Icons.close),
              label: const Text('Huỷ giữ chỗ'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendTile({
    required Color color,
    required String text,
    Color? borderColor,
    Color? textColor,
  }) {
    final resolvedTextColor =
        textColor ?? Theme.of(context).colorScheme.onSurface;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: borderColor == null ? null : Border.all(color: borderColor),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: resolvedTextColor,
          ),
        ),
      ],
    );
  }

  Widget _messageCard({
    required IconData icon,
    required Color color,
    required String message,
    VoidCallback? action,
    String actionLabel = 'Thử lại',
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: color),
            ),
            if (action != null) ...[
              const SizedBox(height: 12),
              FilledButton(
                onPressed: action,
                child: Text(actionLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }

  TimeOfDay? _parseTimeOfDay(String? value) {
    if (value == null || value.isEmpty) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  int _compareTime(TimeOfDay a, TimeOfDay b) {
    return (a.hour * 60 + a.minute) - (b.hour * 60 + b.minute);
  }

  DateTime _combine(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  String? _buildOpeningLabel() {
    final open = _openingStart;
    final close = _closingTime;
    if (open == null || close == null) return null;
    return '${_formatTimeOfDay(open)} - ${_formatTimeOfDay(close)}';
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatTimeRange(DateTime start, DateTime end) {
    final formatter = DateFormat('HH:mm');
    return '${formatter.format(start)} - ${formatter.format(end)}';
  }

  String _describeError(Object error, {required String fallback}) {
    if (error is BookingServiceException) {
      return error.message;
    }
    if (error is CourtServiceException) {
      return error.message;
    }

    final message = error.toString();
    if (message.startsWith('Exception:')) {
      final trimmed = message.substring('Exception:'.length).trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    if (message.isNotEmpty) return message;
    return fallback;
  }
}
