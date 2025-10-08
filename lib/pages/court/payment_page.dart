import 'package:badminton_booking_app/models/court.dart';
import 'package:badminton_booking_app/models/court_booking.dart';
import 'package:flutter/material.dart';

class PaymentPage extends StatelessWidget {
  const PaymentPage({
    super.key,
    required this.booking,
    required this.court,
  });

  final CourtBooking booking;
  final Court court;

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
                children: [
                  _infoTab(cs),
                  const SizedBox(height: 20),
                  _infoBooking(cs),
                ],
              )),

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
                title: Text(court.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
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
                children: [
                  const Icon(Icons.place, size: 20),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      court.location.isNotEmpty
                          ? court.location
                          : 'Địa chỉ đang cập nhật',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 20),
                  const SizedBox(width: 6),
                  Text('${_formatTime(booking.startTime)} - ${_formatTime(booking.endTime)}'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.call, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    court.phone.isNotEmpty ? court.phone : 'Số điện thoại chưa cập nhật',
                    style: const TextStyle(color: Colors.blue),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoBooking(ColorScheme cs) {
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
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 20),
                  const SizedBox(width: 6),
                  Text(_formatDate(booking.startTime)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.access_time_filled, size: 20),
                  const SizedBox(width: 6),
                  Text('${_formatTime(booking.startTime)} - ${_formatTime(booking.endTime)}'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.shield, size: 20),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(_describeStatus(booking.status)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (booking.status != CourtBookingStatus.confirmed)
                Text(
                  'Thanh toán sẽ khả dụng sau khi quản trị viên duyệt đơn đặt sân.',
                  style: TextStyle(color: cs.onSurfaceVariant),
                )
              else
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.payment),
                  label: const Text('Tiến hành thanh toán'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime time) {
    return '${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}/${time.year}';
  }

  String _describeStatus(CourtBookingStatus status) {
    switch (status) {
      case CourtBookingStatus.locked:
        return 'Đang giữ chỗ (chưa gửi duyệt)';
      case CourtBookingStatus.pending:
        return 'Đang chờ quản trị viên duyệt';
      case CourtBookingStatus.confirmed:
        return 'Đã được duyệt - có thể thanh toán';
      case CourtBookingStatus.cancelled:
        return 'Đặt sân đã bị hủy';
    }
  }
}
