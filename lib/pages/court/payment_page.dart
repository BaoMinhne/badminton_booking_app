import 'package:badminton_booking_app/components/my_court_time.dart';
import 'package:badminton_booking_app/models/slot_reservation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({
    super.key,
    required this.holds,
    required this.onConfirmPayment,
    required this.onPayNow,
  });

  final List<SlotReservationInfo> holds;
  final Future<List<SlotReservationInfo>> Function() onConfirmPayment;
  final VoidCallback onPayNow;

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late List<SlotReservationInfo> _holds;
  bool _isProcessing = false;

  bool get _isAwaitingApproval => _holds.isNotEmpty &&
      _holds.every((element) =>
          element.status == SlotReservationStatus.awaitingApproval);

  @override
  void initState() {
    super.initState();
    _holds = widget.holds;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          // List Sân
          Container(
            margin: EdgeInsets.only(top: screenHeight / 13),
            padding: const EdgeInsets.only(top: 20, bottom: 40),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _infoTab(cs),
                const SizedBox(height: 20),
                _bookingSummary(cs),
                const SizedBox(height: 20),
                _actionSection(cs),
              ],
            ),
          ),

          // Title
          Container(
            height: screenHeight / 7,
            decoration: BoxDecoration(
              color: cs.primary,
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 35),
              child: Center(
                child: Text(
                  'P A Y M E N T',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              top: screenHeight / 14,
              left: 12,
            ),
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                child: Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTab(ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Material(
        elevation: 5,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: cs.surface,
            border: Border.all(color: cs.outline, width: 1),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const CircleAvatar(
                  backgroundImage:
                      AssetImage('assets/images/badminton_logo.jpg'),
                  radius: 28,
                ),
                title: const Text("Minh Nghĩa Badminton",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F5EE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text("Cầu lông",
                      style: TextStyle(color: Color(0xFF0E5A3A))),
                ),
              ),
              const Divider(),
              Row(
                children: const [
                  Icon(Icons.place, size: 20),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                        "55D Đ. Trần Nam Phú, Xuân Khánh, Ninh Kiều, Cần Thơ"),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: const [
                  Icon(Icons.schedule, size: 20),
                  SizedBox(width: 6),
                  Text("05:00 - 22:00"),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: const [
                  Icon(Icons.call, size: 20),
                  SizedBox(width: 6),
                  Text(
                    "0329672505",
                    style: TextStyle(color: Colors.blue),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bookingSummary(ColorScheme cs) {
    final format = DateFormat('HH:mm');
    return Material(
      elevation: 5,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: cs.surface,
          border: Border.all(color: cs.outline, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tóm tắt đặt sân',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            if (_holds.isEmpty)
              Text(
                'Bạn chưa chọn khung giờ nào.',
                style: TextStyle(color: cs.onSurface),
              )
            else
              ..._holds.map(
                (slot) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _reservationTile(slot, cs, format),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _reservationTile(
      SlotReservationInfo slot, ColorScheme cs, DateFormat format) {
    final statusColor = slotStatusBorder(slot.status, cs);
    final timeLabel =
        '${slot.startHour.toString().padLeft(2, '0')}:00 - ${(slot.startHour + 1).toString().padLeft(2, '0')}:00';
    final holdLabel = slot.status == SlotReservationStatus.awaitingApproval
        ? 'Đang chờ admin duyệt'
        : (slot.holdUntil != null
            ? 'Giữ đến ${format.format(slot.holdUntil!)}'
            : 'Đang giữ chỗ');

    return Container(
      decoration: BoxDecoration(
        color: slotStatusBackground(slot.status, cs).withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor, width: 1.2),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${slot.courtName} • $timeLabel',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 16, color: statusColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${_statusLabel(slot.status)} • $holdLabel',
                  style: TextStyle(color: cs.onSurface, fontSize: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionSection(ColorScheme cs) {
    return Material(
      elevation: 5,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: cs.surface,
          border: Border.all(color: cs.outline, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isAwaitingApproval || _isProcessing
                  ? null
                  : _handleConfirm,
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Xác nhận thanh toán'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _holds.isEmpty ? null : _handlePayNow,
              child: const Text('Thanh toán ngay'),
            ),
            if (_isAwaitingApproval)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Yêu cầu của bạn đang chờ admin duyệt. Bạn vẫn có thể hoàn tất thanh toán trong lúc này.',
                  style: TextStyle(color: cs.onSurface),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(SlotReservationStatus status) {
    switch (status) {
      case SlotReservationStatus.holding:
        return 'Đang giữ chỗ tạm thời';
      case SlotReservationStatus.awaitingApproval:
        return 'Đã gửi yêu cầu';
      case SlotReservationStatus.booked:
        return 'Đã được đặt';
      case SlotReservationStatus.locked:
        return 'Khung giờ đã khóa';
      case SlotReservationStatus.heldByOthers:
        return 'Người khác đang giữ';
    }
  }

  Future<void> _handleConfirm() async {
    setState(() {
      _isProcessing = true;
    });
    final updated = await widget.onConfirmPayment();
    if (!mounted) return;
    setState(() {
      _holds = updated;
      _isProcessing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã gửi yêu cầu, vui lòng chờ admin duyệt.'),
      ),
    );
  }

  void _handlePayNow() {
    widget.onPayNow();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vui lòng thực hiện thanh toán theo hướng dẫn của sân.'),
      ),
    );
  }
}
