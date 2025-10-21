import 'package:badminton_booking_app/components/my_court_time.dart';
import 'package:badminton_booking_app/models/booking.dart';
import 'package:badminton_booking_app/models/court_detail.dart';
import 'package:badminton_booking_app/pages/auth/auth_manager.dart';
import 'package:badminton_booking_app/pages/court/booking_manager.dart';
import 'package:badminton_booking_app/pages/court/payment_page.dart';
import 'package:badminton_booking_app/services/booking_service.dart';
import 'package:badminton_booking_app/utils/booking_helpers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class BookingPage extends StatefulWidget {
  const BookingPage({
    super.key,
    required this.detailData,
    this.slotDuration = const Duration(hours: 1),
  });

  final CourtDetailData detailData;
  final Duration slotDuration;

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  String? _lastUserId;
  String? _lastCourtId;
  bool _initRequested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = Provider.of<AuthManager>(context);
    final userId = auth.user?.id;
    final manager = Provider.of<BookingManager>(context, listen: false);

    final shouldInit = !_initRequested ||
        _lastCourtId != widget.detailData.court.id ||
        manager.courtId != widget.detailData.court.id ||
        _lastUserId != userId;

    if (shouldInit) {
      final initialDate = manager.isInitialized &&
              manager.courtId == widget.detailData.court.id
          ? manager.date
          : DateTime.now();
      manager.init(
        courtId: widget.detailData.court.id,
        date: initialDate,
        userId: userId,
        slotDuration: widget.slotDuration,
      );
      _initRequested = true;
      _lastCourtId = widget.detailData.court.id;
      _lastUserId = userId;
    } else if (manager.slotDuration != widget.slotDuration) {
      manager.updateSlotDuration(widget.slotDuration);
    }
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<BookingManager>();
    final userId = context.select<AuthManager, String?>(
      (auth) => auth.user?.id,
    );

    final cs = Theme.of(context).colorScheme;
    final rows = _rows;
    final bookings = manager.bookings;
    final selectedSlots = manager.selectedSlots;
    final awaitingPayment = manager.awaitingPaymentBookings.toList(growable: false);
    final heldSlots = manager.heldSlots;
    final holdExpires = manager.holdExpiresAt?.toLocal();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt sân'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại trạng thái đặt sân',
            onPressed: manager.isLoading
                ? null
                : () async {
                    try {
                      await manager.refetch(showLoading: true);
                    } catch (error) {
                      if (!mounted) return;
                      _showError(error);
                    }
                  },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(cs, manager.date, holdExpires, selectedSlots, manager),
          _buildLegend(cs),
          Expanded(
            child: manager.isLoading
                ? const Center(child: CircularProgressIndicator())
                : manager.error != null
                    ? _buildErrorState(cs, manager)
                    : Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: CourtTimeline(
                          rows: rows,
                          date: manager.date,
                          startHour: _startHour,
                          endHour: _endHour,
                          bookings: bookings,
                          selectedSlots: selectedSlots,
                          currentUserId: userId,
                          onSlotTap: (slot, shouldSelect) =>
                              _handleSlotTap(slot, shouldSelect, userId, manager),
                        ),
                      ),
          ),
          _buildSummary(
            cs,
            selectedSlots,
            awaitingPayment,
            holdExpires,
            heldSlots,
            manager,
          ),
        ],
      ),
      bottomNavigationBar: _buildActions(
        cs,
        userId,
        manager,
        awaitingPayment,
      ),
    );
  }

  Future<void> _selectDate(BookingManager manager) async {
    final now = DateTime.now();
    final first = now.subtract(const Duration(days: 1));
    final last = now.add(const Duration(days: 365));

    final picked = await showDatePicker(
      context: context,
      initialDate: manager.date,
      firstDate: first,
      lastDate: last,
    );

    if (picked != null && !_isSameDay(picked, manager.date)) {
      try {
        await manager.changeDate(picked);
      } catch (error) {
        if (!mounted) return;
        _showError(error);
      }
    }
  }

  void _handleSlotTap(
    SelectedSlot slot,
    bool shouldSelect,
    String? userId,
    BookingManager manager,
  ) {
    if (!shouldSelect && manager.heldByMe.containsKey(slot.key)) {
      _cancelHold(slot, manager);
      return;
    }

    if (shouldSelect) {
      if (userId == null) {
        _showLoginRequired();
        return;
      }
      if (manager.isSlotUnavailable(slot, myUserId: userId)) {
        return;
      }
      manager.toggleSelect(slot);
    } else {
      manager.toggleSelect(slot);
    }
  }

  Future<void> _cancelHold(SelectedSlot slot, BookingManager manager) async {
    try {
      await manager.cancelHold(slot);
    } catch (error) {
      if (!mounted) return;
      _showError(error);
    }
  }

  void _showLoginRequired() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Vui lòng đăng nhập để giữ chỗ.')),
    );
  }

  void _showError(Object error) {
    final message =
        error is BookingServiceException ? error.message : 'Đã xảy ra lỗi. Vui lòng thử lại.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildHeader(
    ColorScheme cs,
    DateTime selectedDate,
    DateTime? holdExpires,
    Set<SelectedSlot> selectedSlots,
    BookingManager manager,
  ) {
    final dateLabel = DateFormat('dd/MM/yyyy').format(selectedDate);
    final totalDuration = _totalDuration(selectedSlots);
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
                onPressed: () => _selectDate(manager),
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
                Icon(
                  Icons.hourglass_bottom,
                  size: 18,
                  color: cs.onPrimary.withOpacity(0.9),
                ),
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
              cs.secondaryContainer.withOpacity(0.7), 'Đang giữ chỗ'),
          _legendItem(cs.errorContainer.withOpacity(0.9), 'Người khác giữ'),
          _legendItem(
              cs.tertiaryContainer.withOpacity(0.9), 'Chờ thanh toán'),
          _legendItem(
              cs.primaryContainer.withOpacity(0.9), 'Đã xác nhận'),
        ],
      ),
    );
  }

  Widget _buildSummary(
    ColorScheme cs,
    Set<SelectedSlot> selectedSlots,
    List<CourtBooking> awaitingPayment,
    DateTime? holdExpires,
    List<SelectedSlot> heldSlots,
    BookingManager manager,
  ) {
    final totalPrice = _totalPrice(selectedSlots);

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
                  'Tổng cộng',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
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
          if (awaitingPayment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.pending_actions, size: 20, color: cs.primary),
                const SizedBox(width: 6),
                Text(
                  'Có ${awaitingPayment.length} lượt chờ thanh toán.',
                  style: TextStyle(color: cs.primary),
                ),
              ],
            ),
          ],
          if (heldSlots.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Đang giữ (${heldSlots.length})',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final slot in heldSlots)
                  InputChip(
                    label: Text(_formatSlotLabel(slot)),
                    onDeleted: manager.isMutating
                        ? null
                        : () => _cancelHold(slot, manager),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActions(
    ColorScheme cs,
    String? userId,
    BookingManager manager,
    List<CourtBooking> awaitingPayment,
  ) {
    final hasSelection = manager.selectedSlots.isNotEmpty;
    final hasAwaitingPayment = awaitingPayment.isNotEmpty;

    return SafeArea(
      minimum: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: !hasSelection || manager.isMutating
                  ? null
                  : () async {
                      if (userId == null) {
                        _showLoginRequired();
                        return;
                      }
                      try {
                        await manager.holdSelected(userId: userId);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã giữ chỗ thành công.')),
                        );
                      } catch (error) {
                        if (!mounted) return;
                        _showError(error);
                      }
                    },
              child: manager.isMutating && hasSelection
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('Giữ chỗ (${manager.selectedSlots.length})'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: manager.heldBookings.isEmpty || manager.isMutating
                  ? null
                  : () async {
                      try {
                        await manager.proceedToPayment();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Đã chuyển sang trạng thái chờ thanh toán.')),
                        );
                        await manager.refetch(showLoading: true);
                      } catch (error) {
                        if (!mounted) return;
                        _showError(error);
                      }
                    },
              child: const Text('Chuyển sang thanh toán'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: !hasAwaitingPayment || manager.isMutating
                  ? null
                  : () async {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentPage(
                            detailData: widget.detailData,
                            slotDuration: widget.slotDuration,
                          ),
                        ),
                      );
                      if (result == true && mounted) {
                        await manager.refetch(showLoading: true);
                      }
                    },
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

  Widget _buildErrorState(ColorScheme cs, BookingManager manager) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            manager.error ?? 'Không thể tải dữ liệu.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () async {
              try {
                await manager.refetch(showLoading: true);
              } catch (error) {
                if (!mounted) return;
                _showError(error);
              }
            },
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
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

  Duration _totalDuration(Set<SelectedSlot> slots) {
    var minutes = 0;
    for (final slot in slots) {
      minutes += slot.endTime.difference(slot.startTime).inMinutes;
    }
    return Duration(minutes: minutes);
  }

  double _totalPrice(Set<SelectedSlot> slots) {
    var total = 0.0;
    for (final slot in slots) {
      total += calculateSlotPrice(
        widget.detailData,
        slot,
        widget.slotDuration,
      );
    }
    return total;
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

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatSlotLabel(SelectedSlot slot) {
    final formatter = DateFormat('HH:mm');
    final start = formatter.format(slot.startTime.toLocal());
    final end = formatter.format(slot.endTime.toLocal());
    final courtLabel = _resolveCourtLabel(slot.courtUnitId);
    return '$courtLabel $start-$end';
  }

  String _resolveCourtLabel(String courtUnitId) {
    if (widget.detailData.units.isEmpty) return 'Sân';
    final unit = widget.detailData.units.firstWhere(
      (unit) => unit.id == courtUnitId,
      orElse: () => widget.detailData.units.first,
    );
    return unit.label.isEmpty ? 'Sân' : unit.label;
  }
}
