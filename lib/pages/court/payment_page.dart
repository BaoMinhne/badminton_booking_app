import 'package:badminton_booking_app/models/booking.dart';
import 'package:badminton_booking_app/models/court_detail.dart';
import 'package:badminton_booking_app/pages/court/booking_manager.dart';
import 'package:badminton_booking_app/services/booking_service.dart';
import 'package:badminton_booking_app/utils/booking_helpers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({
    super.key,
    required this.detailData,
    this.slotDuration = const Duration(hours: 1),
  });

  final CourtDetailData detailData;
  final Duration slotDuration;

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  @override
  Widget build(BuildContext context) {
    final manager = context.watch<BookingManager>();
    final bookings = manager.awaitingPaymentBookings.toList(growable: false);
    final slots = _collectSlots(bookings);
    final totalDuration = _totalDuration(slots);
    final durationLabel = totalDuration.inMinutes == 0
        ? '0 phút'
        : '${totalDuration.inMinutes ~/ 60}h ${totalDuration.inMinutes % 60}p';
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildCourtInfoCard(cs),
            const SizedBox(height: 16),
            Expanded(
              child: bookings.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: bookings.length,
                      itemBuilder: (context, index) {
                        final booking = bookings[index];
                        final bookingSlots = booking.splitToSlots(widget.slotDuration);
                        return _buildBookingCard(cs, booking, bookingSlots);
                      },
                    ),
            ),
            const SizedBox(height: 12),
            _buildTotalRow(cs, durationLabel, slots),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: bookings.isEmpty || manager.isMutating
                    ? null
                    : () async {
                        final bookingManager = context.read<BookingManager>();
                        try {
                          await bookingManager.confirmAllAfterPayment();
                          if (!mounted) return;
                          await bookingManager.refetch(showLoading: true);
                          if (!mounted) return;
                          await _showPaymentSuccess();
                          if (!mounted) return;
                          Navigator.of(context).pop(true);
                        } catch (error) {
                          if (!mounted) return;
                          _showError(error);
                        }
                      },
                child: manager.isMutating
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

  Widget _buildCourtInfoCard(ColorScheme cs) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outline.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.detailData.court.name,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.place, size: 18),
                const SizedBox(width: 6),
                Expanded(child: Text(widget.detailData.court.location)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.phone, size: 18),
                const SizedBox(width: 6),
                Text(widget.detailData.court.phone),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(
    ColorScheme cs,
    CourtBooking booking,
    List<SelectedSlot> slots,
  ) {
    final formatter = DateFormat('dd/MM/yyyy');
    final dayLabel = formatter.format(booking.startTime.toLocal());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ngày $dayLabel',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          ...slots.map((slot) => _buildSlotRow(cs, slot)).toList(),
        ],
      ),
    );
  }

  Widget _buildSlotRow(ColorScheme cs, SelectedSlot slot) {
    final timeLabel =
        '${DateFormat.Hm().format(slot.startTime.toLocal())} - ${DateFormat.Hm().format(slot.endTime.toLocal())}';
    final price = calculateSlotPrice(widget.detailData, slot, widget.slotDuration);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${_resolveCourtLabel(slot.courtUnitId)}  $timeLabel',
              style: TextStyle(color: cs.onSurface),
            ),
          ),
          Text(
            formatCurrency(price),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: cs.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(
    ColorScheme cs,
    String durationLabel,
    List<SelectedSlot> slots,
  ) {
    final totalPrice = _totalPrice(slots);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tổng thời gian'),
              Text(
                durationLabel,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Tổng cộng'),
              Text(
                formatCurrency(totalPrice),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
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

  List<SelectedSlot> _collectSlots(List<CourtBooking> bookings) {
    return bookings
        .expand((booking) => booking.splitToSlots(widget.slotDuration))
        .map(
          (slot) => SelectedSlot(
            courtUnitId: slot.courtUnitId,
            startTime: slot.startTime.toUtc(),
            endTime: slot.endTime.toUtc(),
          ),
        )
        .toList(growable: false);
  }

  Duration _totalDuration(List<SelectedSlot> slots) {
    var minutes = 0;
    for (final slot in slots) {
      minutes += slot.endTime.difference(slot.startTime).inMinutes;
    }
    return Duration(minutes: minutes);
  }

  double _totalPrice(List<SelectedSlot> slots) {
    var total = 0.0;
    for (final slot in slots) {
      total += calculateSlotPrice(widget.detailData, slot, widget.slotDuration);
    }
    return total;
  }

  Future<void> _showPaymentSuccess() {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thanh toán thành công'),
        content: const Text(
            'Chúng tôi đã ghi nhận giao dịch của bạn. Chúc bạn có buổi chơi vui vẻ!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hoàn tất'),
          ),
        ],
      ),
    );
  }

  void _showError(Object error) {
    final message =
        error is BookingServiceException ? error.message : 'Đã xảy ra lỗi. Vui lòng thử lại.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
