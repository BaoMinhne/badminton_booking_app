import 'package:badminton_booking_app/models/booking.dart';
import 'package:badminton_booking_app/models/court_detail.dart';
import 'package:badminton_booking_app/pages/court/booking_manager.dart';
import 'package:badminton_booking_app/utils/booking_helpers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool _isProcessingPayment = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingManager>();
    final bookings = provider.awaitingPaymentBookings.toList();
    final slots = _buildSlots(provider, bookings);
    final detail = provider.detailData;

    final totalDuration = _totalDuration(slots);
    final durationLabel = totalDuration.inMinutes == 0
        ? '0 phút'
        : '${totalDuration.inMinutes ~/ 60}h ${totalDuration.inMinutes % 60}p';
    final totalPrice = _totalPrice(provider, slots);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildCourtInfoCard(detail, colorScheme),
            const SizedBox(height: 16),
            Expanded(
              child: bookings.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: bookings.length,
                      itemBuilder: (context, index) {
                        final booking = bookings[index];
                        final bookingSlots = booking.splitToSlots(provider.slotDuration);
                        return _buildBookingCard(colorScheme, provider, booking, bookingSlots);
                      },
                    ),
            ),
            const SizedBox(height: 12),
            _buildTotalRow(colorScheme, durationLabel, totalPrice),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: bookings.isEmpty || _isProcessingPayment
                    ? null
                    : () async => _handlePayment(context),
                child: _isProcessingPayment
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Thanh toán ngay'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  List<SelectedSlot> _buildSlots(
    BookingManager provider,
    List<CourtBooking> bookings,
  ) {
    return bookings
        .expand((booking) => booking.splitToSlots(provider.slotDuration))
        .map((slot) => SelectedSlot(
              courtUnitId: slot.courtUnitId,
              startTime: slot.startTime.toUtc(),
              endTime: slot.endTime.toUtc(),
            ))
        .toList();
  }

  Duration _totalDuration(List<SelectedSlot> slots) {
    var minutes = 0;
    for (final slot in slots) {
      minutes += slot.endTime.difference(slot.startTime).inMinutes;
    }
    return Duration(minutes: minutes);
  }

  double _totalPrice(BookingManager provider, List<SelectedSlot> slots) {
    var total = 0.0;
    for (final slot in slots) {
      total += calculateSlotPrice(provider.detailData, slot, provider.slotDuration);
    }
    return total;
  }

  Widget _buildCourtInfoCard(CourtDetailData detail, ColorScheme colorScheme) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              detail.court.name,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.place, size: 18),
                const SizedBox(width: 6),
                Expanded(child: Text(detail.court.location)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.phone, size: 18),
                const SizedBox(width: 6),
                Text(detail.court.phone),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(
    ColorScheme colorScheme,
    BookingManager provider,
    CourtBooking booking,
    List<SelectedSlot> slots,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time, size: 18),
              const SizedBox(width: 6),
              Text(DateFormat('dd/MM/yyyy HH:mm').format(booking.startTime.toLocal())),
            ],
          ),
          const SizedBox(height: 8),
          ...slots.map((slot) {
            final timeLabel =
                '${DateFormat('HH:mm').format(slot.startTime.toLocal())} - ${DateFormat('HH:mm').format(slot.endTime.toLocal())}';
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('${_resolveCourtLabel(provider, slot.courtUnitId)}  $timeLabel'),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTotalRow(ColorScheme colorScheme, String durationLabel, double totalPrice) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.timer_outlined),
              const SizedBox(width: 8),
              Text('Tổng thời lượng: $durationLabel'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.payments_outlined, color: colorScheme.primary),
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
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.inbox_outlined, size: 48),
          SizedBox(height: 12),
          Text('Chưa có lượt đặt sân nào chờ thanh toán.'),
        ],
      ),
    );
  }

  Future<void> _handlePayment(BuildContext context) async {
    setState(() => _isProcessingPayment = true);

    try {
      await context.read<BookingManager>().confirmAwaitingPaymentBookings();
      if (!mounted) return;
      await _showPaymentSuccess(context);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on BookingManagerException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isProcessingPayment = false);
    }
  }

  Future<void> _showPaymentSuccess(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thanh toán thành công'),
        content: const Text(
          'Chúng tôi đã ghi nhận giao dịch của bạn. Chúc bạn có buổi chơi vui vẻ!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hoàn tất'),
          ),
        ],
      ),
    );
  }

  String _resolveCourtLabel(BookingManager provider, String courtUnitId) {
    final units = provider.detailData.units;
    if (units.isEmpty) {
      return 'Sân';
    }
    final unit = units.firstWhere(
      (item) => item.id == courtUnitId,
      orElse: () => units.first,
    );
    return unit.label.isEmpty ? 'Sân' : unit.label;
  }
}
