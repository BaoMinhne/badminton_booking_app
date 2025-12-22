import 'dart:async';

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
  Timer? _countdownTimer;
  DateTime? _lastNotifiedExpiryAt;

  @override
  void initState() {
    super.initState();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        final provider = context.read<BookingManager>();
        _maybeNotifyPaymentExpiry(provider);
      }
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = Provider.of<AuthManager>(context);
    final provider = Provider.of<BookingManager>(context, listen: false);
    final userId = auth.user?.id;
    if (userId != _lastUserId) {
      _lastUserId = userId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          provider.updateCurrentUser(userId);
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingManager>();
    final colorScheme = Theme.of(context).colorScheme;
    final timelineRows = _buildTimelineRows(provider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book a court'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh booking status',
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
                          bookings: provider.bookingsForVisibleUnits,
                          selectedSlots: provider.selectedSlots,
                          currentUserId: _lastUserId,
                          onSlotTap: (slot, shouldSelect) => _handleSlotTap(
                              context, provider, slot, shouldSelect),
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
    final activeUnits =
        widget.detailData.units.where((unit) => unit.isActive).toList();
    if (activeUnits.isEmpty) {
      return const [CourtTimelineRow(id: 'default', label: 'Court 1')];
    }
    final orderMap = <String, int>{};
    for (var i = 0; i < activeUnits.length; i++) {
      orderMap[activeUnits[i].id] = i + 1;
    }
    final visibleUnits = provider.visibleCourtUnits;
    if (visibleUnits.isEmpty) {
      return activeUnits
          .map(
            (unit) => CourtTimelineRow(
              id: unit.id,
              label: _unitLabel(unit, orderMap),
            ),
          )
          .toList();
    }
    return visibleUnits
        .map(
          (unit) => CourtTimelineRow(
            id: unit.id,
            label: _unitLabel(unit, orderMap),
          ),
        )
        .toList();
  }

  String _unitLabel(CourtUnit unit, Map<String, int> orderMap) {
    if (unit.label.trim().isNotEmpty) {
      return unit.label.trim();
    }
    final index = orderMap[unit.id];
    if (index != null) {
      return 'Court $index';
    }
    return 'Court';
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
            label: 'Reload',
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
        ? 'No time selected'
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
                style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.surface),
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
          if (widget.detailData.units.where((unit) => unit.isActive).length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _buildCourtUnitSelector(provider, colorScheme),
            ),
        ],
      ),
    );
  }

  Widget _buildCourtUnitSelector(
      BookingManager provider, ColorScheme colorScheme) {
    final activeUnits =
        widget.detailData.units.where((unit) => unit.isActive).toList();
    if (activeUnits.isEmpty) {
      return const SizedBox.shrink();
    }
    final orderMap = <String, int>{};
    for (var i = 0; i < activeUnits.length; i++) {
      orderMap[activeUnits[i].id] = i + 1;
    }
    final groups = _chunkUnits(activeUnits, provider.unitGroupSize);
    if (groups.isEmpty) {
      return const SizedBox.shrink();
    }
    final selectedGroupIndex =
        provider.selectedUnitGroupIndex.clamp(0, groups.length - 1).toInt();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
              child: DropdownButton<int>(
                value: selectedGroupIndex,
                onChanged: (value) {
                  if (value != null) {
                    provider.changeCourtUnitGroup(value);
                  }
                },
                items: groups
                    .asMap()
                    .entries
                    .map(
                      (entry) => DropdownMenuItem<int>(
                        value: entry.key,
                        child: Text(
                          _groupLabel(entry.value, orderMap),
                          overflow: TextOverflow.ellipsis,
                        ),
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

  List<List<CourtUnit>> _chunkUnits(List<CourtUnit> units, int groupSize) {
    final chunks = <List<CourtUnit>>[];
    if (units.isEmpty) {
      return chunks;
    }
    for (var i = 0; i < units.length; i += groupSize) {
      final end = i + groupSize;
      chunks.add(units.sublist(i, end > units.length ? units.length : end));
    }
    return chunks;
  }

  String _groupLabel(List<CourtUnit> group, Map<String, int> orderMap) {
    if (group.isEmpty) {
      return 'Court';
    }
    final startLabel = _unitLabel(group.first, orderMap);
    if (group.length == 1) {
      return startLabel;
    }
    final endLabel = _unitLabel(group.last, orderMap);
    return '$startLabel ~ $endLabel';
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
          _legendItem(Colors.white, 'Available'),
          _legendItem(Color(0xFFD9ECFF), 'Held'),
          _legendItem(Color(0xFFF9D7F7), 'Awaiting payment'),
          _legendItem(Color(0xFFFFD9D3), 'Held by others'),
          _legendItem(Color(0xFFDCE3FF), 'Confirmed'),
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
            border: Border.all(color: Colors.black38),
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
            Icon(Icons.warning_amber_rounded,
                color: colorScheme.error, size: 40),
            const SizedBox(height: 12),
            Text(
              provider.friendlyErrorMessage ?? 'Unable to load data.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                provider.refreshBookings();
              },
              child: const Text('Reload'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(BookingManager provider, ColorScheme colorScheme) {
    final holdExpires = provider.holdExpiresAt;
    final awaitingExpires = provider.awaitingPaymentExpiresAt;
    final totalPrice = provider.totalSelectedPrice;

    _syncExpiryNotificationState(awaitingExpires);

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
                      ? 'Select time slots to hold them for up to 15 seconds.'
                      : 'Selected ${provider.selectedSlots.length} slot(s).',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.payments_outlined,
                  size: 20, color: colorScheme.primary),
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
                    'Hold expires at ${DateFormat('HH:mm').format(holdExpires)}.',
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
                Icon(Icons.pending_actions,
                    size: 20, color: colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  '${provider.awaitingPaymentBookings.length} booking(s) awaiting payment.',
                  style: TextStyle(color: colorScheme.primary),
                ),
              ],
            ),
          ],
          if (awaitingExpires != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.timer_outlined,
                    size: 20, color: colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  'Payment time remaining: ${_formatCountdown(awaitingExpires)}',
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
              onPressed:
                  provider.hasHeldBookings && !provider.isSubmittingHeldBookings
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
                  : const Text('Confirm'),
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
              child: const Text('Pay'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: provider.hasAwaitingPaymentBookings
                  ? () async {
                      await provider.cancelAwaitingPaymentBookings();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Awaiting payment bookings have been canceled.'),
                        ),
                      );
                    }
                  : null,
              child: const Text('Cancel hold'),
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
      await provider.submitHeldBookings();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng thanh toán trong vòng 15 phút.'),
        ),
      );
    } on BookingManagerException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          action: SnackBarAction(
            label: 'Reload',
            onPressed: () {
              provider.refreshBookings();
            },
          ),
        ),
      );
    }
  }

  Future<void> _selectDate(
      BuildContext context, BookingManager provider) async {
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

  void _syncExpiryNotificationState(DateTime? awaitingExpires) {
    if (awaitingExpires == null) {
      _lastNotifiedExpiryAt = null;
      return;
    }
    if (_lastNotifiedExpiryAt != null &&
        awaitingExpires.isAfter(_lastNotifiedExpiryAt!)) {
      _lastNotifiedExpiryAt = null;
    }
  }

  Future<void> _maybeNotifyPaymentExpiry(BookingManager provider) async {
    final awaitingExpires = provider.awaitingPaymentExpiresAt;
    if (awaitingExpires == null) {
      _lastNotifiedExpiryAt = null;
      return;
    }
    if (_lastNotifiedExpiryAt != null &&
        _lastNotifiedExpiryAt!.isAtSameMomentAs(awaitingExpires)) {
      return;
    }
    final remaining = awaitingExpires.difference(DateTime.now().toUtc());
    if (remaining.isNegative || remaining == Duration.zero) {
      _lastNotifiedExpiryAt = awaitingExpires;
      await provider.refreshBookings();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Payment expired'),
          content: const Text(
            'You did not complete payment within the required time. Your '
            'booking has been released.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  String _formatCountdown(DateTime expiresAt) {
    final remaining = expiresAt.difference(DateTime.now().toUtc());
    final safe = remaining.isNegative ? Duration.zero : remaining;
    final minutes = safe.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = safe.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = safe.inHours;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}
