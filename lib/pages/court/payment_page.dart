import 'package:badminton_booking_app/models/booking.dart';
import 'package:badminton_booking_app/models/court_detail.dart';
import 'package:badminton_booking_app/services/booking_service.dart';
import 'package:badminton_booking_app/utils/booking_helpers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({
    super.key,
    required this.detailData,
    required this.bookings,
    this.slotDuration = const Duration(hours: 1),
    this.bookingService,
  });

  final CourtDetailData detailData;
  final List<CourtBooking> bookings;
  final Duration slotDuration;
  final BookingService? bookingService;

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late BookingService _bookingService;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _bookingService = widget.bookingService ?? BookingService();
  }

  List<SelectedSlot> get _slots {
    return widget.bookings
        .expand((booking) => booking.splitToSlots(widget.slotDuration))
        .map((slot) => SelectedSlot(
              courtUnitId: slot.courtUnitId,
              startTime: slot.startTime.toUtc(),
              endTime: slot.endTime.toUtc(),
            ))
        .toList();
  }

  Duration get _totalDuration {
    var minutes = 0;
    for (final slot in _slots) {
      minutes += slot.endTime.difference(slot.startTime).inMinutes;
    }
    return Duration(minutes: minutes);
  }

  double get _totalPrice {
    var total = 0.0;
    for (final slot in _slots) {
      total += calculateSlotPrice(widget.detailData, slot, widget.slotDuration);
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final totalDuration = _totalDuration;
    final durationLabel = totalDuration.inMinutes == 0
        ? '0 phút'
        : '${totalDuration.inMinutes ~/ 60}h ${totalDuration.inMinutes % 60}p';

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
              child: widget.bookings.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: widget.bookings.length,
                      itemBuilder: (context, index) {
                        final booking = widget.bookings[index];
                        final slots = booking.splitToSlots(widget.slotDuration);
                        return _buildBookingCard(cs, booking, slots);
                      },
                    ),
            ),
            const SizedBox(height: 12),
            _buildTotalRow(cs, durationLabel),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: widget.bookings.isEmpty || _processing
                    ? null
                    : _handlePayment,
                child: _processing
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
    final price =
        calculateSlotPrice(widget.detailData, slot, widget.slotDuration);

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

  Widget _buildTotalRow(ColorScheme cs, String durationLabel) {
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
                formatCurrency(_totalPrice),
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

  Future<void> _handlePayment() async {
    setState(() => _processing = true);

    try {
      for (final booking in widget.bookings) {
        await _bookingService.markAsConfirmed(booking.id);
      }

      if (!mounted) return;
      await _showPaymentSuccess(context);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_describeError(error))),
      );
    } finally {
      if (!mounted) return;
      setState(() => _processing = false);
    }
  }

  Future<void> _showPaymentSuccess(BuildContext context) {
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

  String _describeError(Object error) {
    if (error is BookingServiceException) {
      return error.message;
    }
    return 'Đã xảy ra lỗi. Vui lòng thử lại.';
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
