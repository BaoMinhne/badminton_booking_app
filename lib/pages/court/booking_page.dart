import 'package:badminton_booking_app/components/my_court_time.dart';
import 'package:badminton_booking_app/models/booking.dart';
import 'package:badminton_booking_app/models/court_detail.dart';
import 'package:badminton_booking_app/pages/court/payment_page.dart';
import 'package:badminton_booking_app/pages/auth/auth_manager.dart';
import 'package:badminton_booking_app/services/booking_service.dart';
import 'package:badminton_booking_app/utils/booking_helpers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class BookingPage extends StatefulWidget {
  const BookingPage({
    super.key,
    required this.detailData,
    this.bookingService,
    this.slotDuration = const Duration(hours: 1),
  });

  final CourtDetailData detailData;
  final BookingService? bookingService;
  final Duration slotDuration;

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  late DateTime _selectedDate;
  late BookingService _bookingService;

  final Set<SelectedSlot> _otherBookedSlots = {};

  final Set<SelectedSlot> _selectedSlots = <SelectedSlot>{};
  final Map<SelectedSlot, CourtBooking> _heldBookings = {};
  final Set<SelectedSlot> _processingSlots = {};

  BookingRealtimeSubscription? _realtimeSubscription;

  List<CourtBooking> _bookings = <CourtBooking>[];

  bool _isLoading = false;
  String? _errorMessage;
  bool _submittingRequest = false;
  String? _currentUserId;
  bool _hasRealtimeInitialized = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _bookingService = widget.bookingService ?? BookingService();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = Provider.of<AuthManager>(context);
    final previousUserId = _currentUserId;
    final newUserId = auth.user?.id;
    final shouldRestart =
        !_hasRealtimeInitialized || newUserId != previousUserId;
    if (shouldRestart) {
      _currentUserId = newUserId;
      _hasRealtimeInitialized = true;
      if (previousUserId != newUserId) {
        _selectedSlots.clear();
        _heldBookings.clear();
      }
      _restartRealtime();
    }
  }

  @override
  void didUpdateWidget(covariant BookingPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detailData.court.id != widget.detailData.court.id) {
      _restartRealtime();
    } else if (oldWidget.slotDuration != widget.slotDuration) {
      _applyBookings(_bookings, clearError: false);
    }
  }

  Future<void> _loadBookings() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final bookings = await _bookingService.listBookings(
        courtId: widget.detailData.court.id,
        date: _selectedDate,
      );
      if (!mounted) return;
      _applyBookings(bookings);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _describeError(error);
        _isLoading = false;
      });
    }
  }

  void _applyBookings(List<CourtBooking> bookings, {bool clearError = true}) {
    if (!mounted) return;
    final newSelected = <SelectedSlot>{};
    final newHeld = <SelectedSlot, CourtBooking>{};
    final newOtherBooked = <SelectedSlot>{};

    final now = DateTime.now().toUtc();

    for (final booking in bookings) {
      // Phân loại booking theo trạng thái
      final isConfirmed = booking.status == BookingStatus.confirmed;
      final isAwaitingPayment = booking.status == BookingStatus.awaitingPayment;
      final isHeld = booking.status == BookingStatus.held &&
          (booking.lockedUntil == null || booking.lockedUntil!.isAfter(now));

      // Phân loại theo người dùng
      if (booking.userId == _currentUserId) {
        if (isHeld) {
          for (final slot in booking.splitToSlots(widget.slotDuration)) {
            final canonical = _canonicalizeSlot(slot);
            newSelected.add(canonical);
            newHeld[canonical] = booking;
          }
        }
      } else {
        // Đây là booking của người dùng khác
        if (isConfirmed || isAwaitingPayment || isHeld) {
          for (final slot in booking.splitToSlots(widget.slotDuration)) {
            newOtherBooked.add(_canonicalizeSlot(slot));
          }
        }
      }
    }

    setState(() {
      _bookings = bookings;
      _selectedSlots.clear();
      _selectedSlots.addAll(newSelected);
      _heldBookings.clear();
      _heldBookings.addAll(newHeld);
      _otherBookedSlots.clear();
      _otherBookedSlots.addAll(newOtherBooked);
      _isLoading = false;
      if (clearError) {
        _errorMessage = null;
      }
    });
  }

  Future<void> _restartRealtime({bool emitInitial = true}) async {
    final previous = _realtimeSubscription;
    _realtimeSubscription = null;
    if (previous != null) {
      await previous.cancel();
    }

    if (!mounted) {
      return;
    }

    if (emitInitial) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final subscription = await _bookingService.subscribeToBookings(
        courtId: widget.detailData.court.id,
        date: _selectedDate,
        emitInitial: emitInitial,
        onData: (bookings) {
          if (!mounted) return;
          _applyBookings(bookings);
        },
        onError: (error) {
          if (!mounted) return;
          setState(() {
            _errorMessage = _describeError(error);
            _isLoading = false;
          });
        },
      );
      _realtimeSubscription = subscription;
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _describeError(error);
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final first = DateTime.now().subtract(const Duration(days: 1));
    final last = DateTime.now().add(const Duration(days: 365));

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: first,
      lastDate: last,
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      await _restartRealtime();
    }
  }

  void _handleSlotTap(SelectedSlot slot, bool shouldSelect) {
    final canonical = _canonicalizeSlot(slot);

    // Thêm điều kiện kiểm tra slot đã bị đặt bởi người khác
    if (_otherBookedSlots.contains(canonical)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Khung giờ này đã có người khác giữ hoặc đặt.')),
      );
      return;
    }

    if (_processingSlots.contains(canonical)) {
      return;
    }

    if (shouldSelect) {
      if (_currentUserId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng đăng nhập để giữ chỗ.')),
        );
        return;
      }
      _lockSlot(canonical);
    } else {
      _releaseSlot(canonical);
    }
  }

  Future<void> _lockSlot(SelectedSlot slot) async {
    setState(() => _processingSlots.add(slot));

    try {
      final booking = await _bookingService.lockSlot(
        courtId: widget.detailData.court.id,
        courtUnitId: slot.courtUnitId,
        userId: _currentUserId!,
        startTime: slot.startTime.toUtc(),
        endTime: slot.endTime.toUtc(),
      );

      final bookingSlots = booking.splitToSlots(widget.slotDuration);
      if (!mounted) return;
      setState(() {
        _bookings = [..._bookings, booking];
        for (final item in bookingSlots) {
          final canonical = _canonicalizeSlot(item);
          _selectedSlots.add(canonical);
          _heldBookings[canonical] = booking;
        }
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_describeError(error))),
      );
    } finally {
      if (!mounted) return;
      setState(() => _processingSlots.remove(slot));
    }
  }

  Future<void> _releaseSlot(SelectedSlot slot) async {
    final booking = _heldBookings.remove(slot);
    if (booking == null) {
      setState(() => _selectedSlots.remove(slot));
      return;
    }

    setState(() {
      _processingSlots.add(slot);
    });

    try {
      await _bookingService.releaseBooking(booking.id);
      if (!mounted) return;
      setState(() {
        _selectedSlots.remove(slot);
        _bookings.removeWhere((item) => item.id == booking.id);
      });
    } catch (error) {
      if (!mounted) return;
      _heldBookings[slot] = booking;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_describeError(error))),
      );
    } finally {
      if (!mounted) return;
      setState(() => _processingSlots.remove(slot));
    }
  }

  // CHANGED: đổi tên hàm và text sang "chuyển sang chờ thanh toán"
  Future<void> _proceedToAwaitingPayment() async {
    if (_heldBookings.isEmpty) return;
    setState(() => _submittingRequest = true);

    try {
      final updates = <CourtBooking>[];
      for (final booking in _heldBookings.values) {
        // vẫn gọi service cũ, nhưng service nên update status = 'awaiting_payment'
        final updated = await _bookingService.submitForApproval(booking.id);
        updates.add(updated);
      }

      if (!mounted) return;
      setState(() {
        for (final updated in updates) {
          _bookings.removeWhere((item) => item.id == updated.id);
          _bookings.add(updated);
        }
        _selectedSlots.clear();
        _heldBookings.clear();
        _submittingRequest = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã chuyển sang trạng thái chờ thanh toán.'),
        ),
      );
      await _loadBookings();
    } catch (error) {
      if (!mounted) return;
      setState(() => _submittingRequest = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_describeError(error))),
      );
    }
  }

  List<CourtTimelineRow> get _rows {
    final units = widget.detailData.units;
    if (units.isEmpty) {
      return [const CourtTimelineRow(id: 'default', label: 'Sân 1')];
    }
    return units
        .where((unit) => unit.isActive)
        .map((unit) => CourtTimelineRow(
              id: unit.id,
              label: unit.label.isEmpty ? 'Sân' : unit.label,
            ))
        .toList();
  }

  Duration get _totalDuration {
    var minutes = 0;
    for (final slot in _selectedSlots) {
      minutes += slot.endTime.difference(slot.startTime).inMinutes;
    }
    return Duration(minutes: minutes);
  }

  double get _totalPrice {
    var total = 0.0;
    for (final slot in _selectedSlots) {
      total += calculateSlotPrice(
        widget.detailData,
        slot,
        widget.slotDuration,
      );
    }
    return total;
  }

  // CHANGED: dùng awaitingPayment thay cho confirmed
  Iterable<CourtBooking> get _awaitingPaymentForUser {
    if (_currentUserId == null) return const Iterable.empty();
    return _bookings.where((booking) =>
        booking.userId == _currentUserId &&
        booking.status == BookingStatus.awaitingPayment);
  }

  Iterable<CourtBooking> get _blockingBookingsFromOthers {
    final now = DateTime.now().toUtc();
    return _bookings.where((booking) {
      if (booking.userId == _currentUserId) {
        return false;
      }

      switch (booking.status) {
        case BookingStatus.confirmed:
        case BookingStatus.awaitingPayment:
          return true;
        case BookingStatus.held:
          return booking.lockedUntil == null ||
              booking.lockedUntil!.isAfter(now);
        case BookingStatus.cancelled:
        case BookingStatus.expired:
          return false;
      }
    });
  }

  String _labelForCourtUnit(String unitId) {
    for (final unit in widget.detailData.units) {
      if (unit.id == unitId) {
        return unit.label.isEmpty ? 'Sân' : unit.label;
      }
    }
    return 'Sân';
  }

  String _formatBookingTimeRange(CourtBooking booking) {
    final start = DateFormat('HH:mm').format(booking.startTime.toLocal());
    final end = DateFormat('HH:mm').format(booking.endTime.toLocal());
    return '$start - $end';
  }

  String _describeOtherBookingStatus(CourtBooking booking) {
    switch (booking.status) {
      case BookingStatus.confirmed:
        return 'Đã xác nhận';
      case BookingStatus.awaitingPayment:
        return 'Chờ thanh toán';
      case BookingStatus.held:
        return 'Đang giữ chỗ';
      case BookingStatus.cancelled:
      case BookingStatus.expired:
        return '';
    }
  }

  int get _startHour {
    final minutes = widget.detailData.openingHours
        .map((item) => parseTimeToMinutes(item.openTime))
        .whereType<int>();
    if (minutes.isEmpty) return 6;
    final minMinute = minutes.reduce((a, b) => a < b ? a : b);
    final base = (minMinute / 60).floor();
    if (base < 0) return 0;
    if (base > 23) return 23;
    return base;
  }

  int get _endHour {
    final minutes = widget.detailData.openingHours
        .map((item) => parseTimeToMinutes(item.closeTime))
        .whereType<int>();
    if (minutes.isEmpty) return 22;
    final maxMinute = minutes.reduce((a, b) => a > b ? a : b);
    var endHour = (maxMinute / 60).ceil();
    if (endHour < 1) {
      endHour = 1;
    } else if (endHour > 24) {
      endHour = 24;
    }
    return endHour <= _startHour ? _startHour + 1 : endHour;
  }

  DateTime? get _holdExpiresAt {
    DateTime? result;
    for (final booking in _heldBookings.values) {
      final locked = booking.lockedUntil?.toLocal();
      if (locked == null) continue;
      if (result == null || locked.isBefore(result)) {
        result = locked;
      }
    }
    return result;
  }

  SelectedSlot _canonicalizeSlot(SelectedSlot slot) {
    return SelectedSlot(
      courtUnitId: slot.courtUnitId,
      startTime: slot.startTime.toUtc(),
      endTime: slot.endTime.toUtc(),
    );
  }

  @override
  void dispose() {
    final subscription = _realtimeSubscription;
    _realtimeSubscription = null;
    subscription?.cancel();
    super.dispose();
  }

  String _describeError(Object error) {
    if (error is BookingServiceException) {
      return error.message;
    }
    return 'Đã xảy ra lỗi. Vui lòng thử lại.';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final rows = _rows;
    final holdExpires = _holdExpiresAt;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt sân'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : () => _restartRealtime(),
            tooltip: 'Tải lại trạng thái đặt sân',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(cs, holdExpires),
          _buildLegend(cs),
          if (_blockingBookingsFromOthers.isNotEmpty)
            _buildOtherBookingsNotice(cs),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildErrorState(cs)
                    : Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: CourtTimeline(
                          rows: rows,
                          date: _selectedDate,
                          startHour: _startHour,
                          endHour: _endHour,
                          bookings: _bookings, // Giữ nguyên bookings
                          selectedSlots:
                              _selectedSlots, // Giữ nguyên selectedSlots
                          otherBookedSlots: _otherBookedSlots, // THÊM DÒNG NÀY
                          currentUserId: _currentUserId,
                          onSlotTap: _handleSlotTap,
                        ),
                      ),
          ),
          _buildSummary(cs, holdExpires),
        ],
      ),
      bottomNavigationBar: _buildActions(cs),
    );
  }

  Widget _buildHeader(ColorScheme cs, DateTime? holdExpires) {
    final dateLabel = DateFormat('dd/MM/yyyy').format(_selectedDate);
    final totalDuration = _totalDuration;
    final durationLabel = totalDuration.inMinutes == 0
        ? 'Chưa chọn thời gian'
        : '${totalDuration.inMinutes ~/ 60}h ${totalDuration.inMinutes % 60}p';

    return Container(
      color: cs.primary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                widget.detailData.court.name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: cs.onPrimary,
                ),
              ),
              const Spacer(),
              FilledButton.tonal(
                style: FilledButton.styleFrom(
                  backgroundColor: cs.surface,
                ),
                onPressed: _selectDate,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dateLabel,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.calendar_month, color: cs.onSurface),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.schedule, color: cs.onPrimary.withOpacity(0.9)),
              const SizedBox(width: 6),
              Text(
                durationLabel,
                style: TextStyle(
                  color: cs.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (holdExpires != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.hourglass_bottom,
                    size: 18, color: cs.onPrimary.withOpacity(0.9)),
                const SizedBox(width: 6),
                Text(
                  'Giữ chỗ đến ${DateFormat('HH:mm').format(holdExpires)}',
                  style: TextStyle(color: cs.onPrimary),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegend(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withOpacity(0.4)),
        ),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          _legendItem(
              cs.secondaryContainer.withOpacity(0.7), 'Đang giữ chỗ'), // held
          _legendItem(cs.errorContainer.withOpacity(0.9), 'Người khác giữ'),
          _legendItem(cs.tertiaryContainer.withOpacity(0.9),
              'Chờ thanh toán'), // CHANGED
          _legendItem(
              cs.primaryContainer.withOpacity(0.9), 'Đã xác nhận'), // CHANGED
        ],
      ),
    );
  }

  Widget _buildOtherBookingsNotice(ColorScheme cs) {
    final bookings = _blockingBookingsFromOthers.toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_clock, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Các khung giờ đã có người đặt',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...bookings.map(
            (booking) {
              final statusLabel = _describeOtherBookingStatus(booking);
              final parts = [
                _formatBookingTimeRange(booking),
                _labelForCourtUnit(booking.courtUnitId),
                if (statusLabel.isNotEmpty) statusLabel,
              ];
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  parts.join(' • '),
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(ColorScheme cs, DateTime? holdExpires) {
    final totalPrice = _totalPrice;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sticky_note_2_outlined, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedSlots.isEmpty
                      ? 'Chọn khung giờ để giữ chỗ tối đa 15 phút.'
                      : 'Đã chọn ${_selectedSlots.length} khung giờ.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.payments_outlined, size: 20, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                formatCurrency(totalPrice),
                style: TextStyle(
                  color: cs.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          // CHANGED: thông báo số booking chờ thanh toán thay vì đã duyệt
          if (_awaitingPaymentForUser.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.pending_actions, size: 20, color: cs.primary),
                const SizedBox(width: 6),
                Text(
                  'Có ${_awaitingPaymentForUser.length} lượt chờ thanh toán.',
                  style: TextStyle(color: cs.primary),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActions(ColorScheme cs) {
    // CHANGED: bật thanh toán khi có booking awaiting_payment
    final hasAwaitingPayment = _awaitingPaymentForUser.isNotEmpty;

    return SafeArea(
      minimum: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _heldBookings.isEmpty || _submittingRequest
                  ? null
                  : _proceedToAwaitingPayment, // CHANGED
              child: _submittingRequest
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Chuyển sang thanh toán'), // CHANGED
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: hasAwaitingPayment
                  ? () async {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentPage(
                            detailData: widget.detailData,
                            bookings:
                                _awaitingPaymentForUser.toList(), // CHANGED
                            slotDuration: widget.slotDuration,
                            bookingService: _bookingService,
                          ),
                        ),
                      );

                      if (result == true && mounted) {
                        await _loadBookings();
                      }
                    }
                  : null,
              child: const Text('Thanh toán'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: Colors.black12),
          ),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }

  Widget _buildErrorState(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _errorMessage ?? 'Không thể tải dữ liệu.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => _restartRealtime(),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}
