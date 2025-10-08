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

  final Set<SelectedSlot> _selectedSlots = <SelectedSlot>{};
  final Map<SelectedSlot, CourtBooking> _heldBookings = {};
  final Set<SelectedSlot> _processingSlots = {};

  List<CourtBooking> _bookings = <CourtBooking>[];

  bool _isLoading = false;
  String? _errorMessage;
  bool _submittingRequest = false;
  String? _currentUserId;

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
    final newUserId = auth.user?.id;
    if (newUserId != _currentUserId) {
      _currentUserId = newUserId;
      _loadBookings();
    }
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final bookings = await _bookingService.listBookings(
        courtId: widget.detailData.court.id,
        date: _selectedDate,
      );

      final newSelected = <SelectedSlot>{};
      final newHeld = <SelectedSlot, CourtBooking>{};

      if (_currentUserId != null) {
        for (final booking in bookings) {
          if (booking.userId == _currentUserId &&
              booking.status == BookingStatus.locked &&
              booking.isActiveLock) {
            for (final slot in booking.splitToSlots(widget.slotDuration)) {
              final canonical = _canonicalizeSlot(slot);
              newSelected.add(canonical);
              newHeld[canonical] = booking;
            }
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _bookings = bookings;
        _selectedSlots
          ..clear()
          ..addAll(newSelected);
        _heldBookings
          ..clear()
          ..addAll(newHeld);
        _isLoading = false;
      });
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
      await _loadBookings();
    }
  }

  void _handleSlotTap(SelectedSlot slot, bool shouldSelect) {
    final canonical = _canonicalizeSlot(slot);
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

  Future<void> _submitForApproval() async {
    if (_heldBookings.isEmpty) return;
    setState(() => _submittingRequest = true);

    try {
      final updates = <CourtBooking>[];
      for (final booking in _heldBookings.values) {
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
          content: Text('Đã gửi yêu cầu giữ chỗ. Vui lòng chờ quản lý duyệt.'),
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

  Iterable<CourtBooking> get _confirmedBookingsForUser {
    if (_currentUserId == null) return const Iterable.empty();
    return _bookings.where((booking) =>
        booking.userId == _currentUserId &&
        booking.status == BookingStatus.confirmed);
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
            onPressed: _isLoading ? null : _loadBookings,
            tooltip: 'Tải lại trạng thái đặt sân',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(cs, holdExpires),
          _buildLegend(cs),
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
                          bookings: _bookings,
                          selectedSlots: _selectedSlots,
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
          _legendItem(cs.secondaryContainer.withOpacity(0.7), 'Đang giữ chỗ'),
          _legendItem(cs.errorContainer.withOpacity(0.9), 'Người khác giữ'),
          _legendItem(cs.tertiaryContainer.withOpacity(0.9), 'Chờ duyệt'),
          _legendItem(cs.primaryContainer.withOpacity(0.9), 'Đã duyệt'),
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
          if (_confirmedBookingsForUser.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.check_circle, size: 20, color: cs.primary),
                const SizedBox(width: 6),
                Text(
                  'Đã có ${_confirmedBookingsForUser.length} lượt được duyệt.',
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
    final hasConfirmed = _confirmedBookingsForUser.isNotEmpty;

    return SafeArea(
      minimum: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed:
                  _heldBookings.isEmpty || _submittingRequest ? null : _submitForApproval,
              child: _submittingRequest
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Gửi yêu cầu đặt sân'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: hasConfirmed
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentPage(
                            detailData: widget.detailData,
                            bookings: _confirmedBookingsForUser.toList(),
                            slotDuration: widget.slotDuration,
                          ),
                        ),
                      );
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
            onPressed: _loadBookings,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}
