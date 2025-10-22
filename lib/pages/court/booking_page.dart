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

class BookingPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<BookingManager>(
      create: (_) => BookingManager(
        detailData: detailData,
        bookingService: bookingService,
        slotDuration: slotDuration,
      ),
      child: _BookingPageView(detailData: detailData),
    );
  }
}

class _BookingPageView extends StatefulWidget {
  const _BookingPageView({required this.detailData});

  final CourtDetailData detailData;

  @override
  State<_BookingPageView> createState() => _BookingPageViewState();
}

class _BookingPageViewState extends State<_BookingPageView> {
  String? _lastUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = Provider.of<AuthManager>(context);
    final provider = Provider.of<BookingManager>(context, listen: false);
    final userId = auth.user?.id;
    if (userId != _lastUserId) {
      _lastUserId = userId;
      provider.updateCurrentUser(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingManager>();
    final colorScheme = Theme.of(context).colorScheme;
    final timelineRows = _buildTimelineRows(provider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt sân'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại trạng thái đặt sân',
            onPressed: provider.isLoading
                ? null
                : () {
                    provider.refreshBookings();
                  },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context, provider, colorScheme),
          _buildLegend(colorScheme),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.friendlyErrorMessage != null
                    ? _buildErrorState(context, provider, colorScheme)
                    : Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: CourtTimeline(
                          rows: timelineRows,
                          date: provider.selectedDate,
                          startHour: _resolveStartHour(),
                          endHour: _resolveEndHour(),
                          bookings: provider.bookings,
                          selectedSlots: provider.selectedSlots,
                          currentUserId: _lastUserId,
                          onSlotTap: (slot, shouldSelect) =>
                              _handleSlotTap(context, provider, slot, shouldSelect),
                        ),
                      ),
          ),
          _buildSummary(provider, colorScheme),
        ],
      ),
      bottomNavigationBar: _buildActions(context, provider, colorScheme),
    );
  }

  List<CourtTimelineRow> _buildTimelineRows(BookingManager provider) {
    final units = widget.detailData.units.where((unit) => unit.isActive).toList();
    if (units.isEmpty) {
      return const [CourtTimelineRow(id: 'default', label: 'Sân 1')];
    }
    final selectedId = provider.selectedCourtUnitId;
    if (selectedId == null) {
      return units
          .map((unit) => CourtTimelineRow(
                id: unit.id,
                label: unit.label.isEmpty ? 'Sân' : unit.label,
              ))
          .toList();
    }
    final unit = units.firstWhere(
      (item) => item.id == selectedId,
      orElse: () => units.first,
    );
    return [
      CourtTimelineRow(
        id: unit.id,
        label: unit.label.isEmpty ? 'Sân' : unit.label,
      ),
    ];
  }

  Future<void> _handleSlotTap(
    BuildContext context,
    BookingManager provider,
    SelectedSlot slot,
    bool shouldSelect,
  ) async {
    if (provider.isSlotInProgress(slot)) {
      return;
    }

    try {
      if (shouldSelect) {
        await provider.holdSlot(slot);
      } else {
        await provider.releaseSlot(slot);
      }
    } on BookingManagerException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          action: SnackBarAction(
            label: 'Tải lại',
            onPressed: () {
              provider.refreshBookings();
            },
          ),
        ),
      );
    }
  }

  Widget _buildHeader(
    BuildContext context,
    BookingManager provider,
    ColorScheme colorScheme,
  ) {
    final dateLabel = DateFormat('dd/MM/yyyy').format(provider.selectedDate);
    final totalDuration = provider.totalSelectedDuration;
    final durationLabel = totalDuration.inMinutes == 0
        ? 'Chưa chọn thời gian'
        : '${totalDuration.inMinutes ~/ 60}h ${totalDuration.inMinutes % 60}p';

    return Container(
      color: colorScheme.primary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.detailData.court.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
              FilledButton.tonal(
                style: FilledButton.styleFrom(backgroundColor: colorScheme.surface),
                onPressed: () => _selectDate(context, provider),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dateLabel,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.calendar_month, color: colorScheme.onSurface),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.schedule, color: colorScheme.onPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  durationLabel,
                  style: TextStyle(color: colorScheme.onPrimary),
                ),
              ),
            ],
          ),
          if (widget.detailData.units.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _buildCourtUnitSelector(provider, colorScheme),
            ),
        ],
      ),
    );
  }

  Widget _buildCourtUnitSelector(BookingManager provider, ColorScheme colorScheme) {
    final units = widget.detailData.units.where((unit) => unit.isActive).toList();
    final selectedId = provider.selectedCourtUnitId ??
        (units.isNotEmpty ? units.first.id : null);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.sports_tennis, color: colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedId,
                onChanged: (value) {
                  if (value != null) {
                    provider.changeCourtUnit(value);
                  }
                },
                items: units
                    .map(
                      (unit) => DropdownMenuItem<String>(
                        value: unit.id,
                        child: Text(unit.label.isEmpty ? 'Sân' : unit.label),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: colorScheme.surface,
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _legendItem(colorScheme.primary.withOpacity(0.2), 'Có thể đặt'),
          _legendItem(colorScheme.primary, 'Bạn đang giữ chỗ'),
          _legendItem(colorScheme.secondary, 'Người khác giữ chỗ'),
          _legendItem(colorScheme.tertiary, 'Chờ thanh toán'),
          _legendItem(colorScheme.error, 'Đã xác nhận'),
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

  Widget _buildErrorState(
    BuildContext context,
    BookingManager provider,
    ColorScheme colorScheme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, color: colorScheme.error, size: 40),
            const SizedBox(height: 12),
            Text(
              provider.friendlyErrorMessage ?? 'Không thể tải dữ liệu.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                provider.refreshBookings();
              },
              child: const Text('Tải lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(BookingManager provider, ColorScheme colorScheme) {
    final holdExpires = provider.holdExpiresAt;
    final totalPrice = provider.totalSelectedPrice;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.sticky_note_2_outlined, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  provider.selectedSlots.isEmpty
                      ? 'Chọn khung giờ để giữ chỗ tối đa 15 phút.'
                      : 'Đã chọn ${provider.selectedSlots.length} khung giờ.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.payments_outlined, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                formatCurrency(totalPrice),
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          if (holdExpires != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.timer_outlined, size: 20, color: colorScheme.error),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Giữ chỗ hết hạn lúc ${DateFormat('HH:mm').format(holdExpires)}.',
                    style: TextStyle(color: colorScheme.error),
                  ),
                ),
              ],
            ),
          ],
          if (provider.hasAwaitingPaymentBookings) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.pending_actions, size: 20, color: colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  'Có ${provider.awaitingPaymentBookings.length} lượt chờ thanh toán.',
                  style: TextStyle(color: colorScheme.primary),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActions(
    BuildContext context,
    BookingManager provider,
    ColorScheme colorScheme,
  ) {
    return SafeArea(
      minimum: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: provider.hasHeldBookings && !provider.isSubmittingHeldBookings
                  ? () async {
                      await _handleSubmitForPayment(context, provider);
                    }
                  : null,
              child: provider.isSubmittingHeldBookings
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Chuyển sang thanh toán'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: provider.hasAwaitingPaymentBookings
                  ? () async {
                      final providerInstance = context.read<BookingManager>();
                      final result = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (context) => ChangeNotifierProvider.value(
                            value: providerInstance,
                            child: const PaymentPage(),
                          ),
                        ),
                      );
                      if (result == true && mounted) {
                        await provider.refreshBookings();
                      }
                    }
                  : null,
              child: const Text('Thanh toán'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: provider.hasHeldBookings
                  ? () async {
                      await provider.cancelHeldBookings();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã huỷ giữ chỗ hiện tại.')),
                      );
                    }
                  : null,
              child: const Text('Huỷ giữ chỗ'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmitForPayment(
    BuildContext context,
    BookingManager provider,
  ) async {
    try {
      await provider.submitHeldBookingsForPayment();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã chuyển sang trạng thái chờ thanh toán.')),
      );
    } on BookingManagerException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          action: SnackBarAction(
            label: 'Tải lại',
            onPressed: () {
              provider.refreshBookings();
            },
          ),
        ),
      );
    }
  }

  Future<void> _selectDate(BuildContext context, BookingManager provider) async {
    final today = DateTime.now();
    final first = today.subtract(const Duration(days: 1));
    final last = today.add(const Duration(days: 365));

    final picked = await showDatePicker(
      context: context,
      initialDate: provider.selectedDate,
      firstDate: first,
      lastDate: last,
    );

    if (picked != null) {
      await provider.changeDate(picked);
    }
  }

  int _resolveStartHour() {
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

  int _resolveEndHour() {
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
    final start = _resolveStartHour();
    return endHour <= start ? start + 1 : endHour;
  }
}
