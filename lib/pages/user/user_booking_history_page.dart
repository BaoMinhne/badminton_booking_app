import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/user_booking_tile.dart';
import '../../models/user_booking_view.dart';
import '../../services/booking_service.dart';
import 'user_manager.dart';

class UserBookingHistoryPage extends StatefulWidget {
  const UserBookingHistoryPage({super.key});

  @override
  State<UserBookingHistoryPage> createState() =>
      _UserBookingHistoryPageState();
}

class _UserBookingHistoryPageState extends State<UserBookingHistoryPage> {
  final BookingService _bookingService = BookingService();
  Future<List<UserBookingView>>? _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _loadHistory();
  }

  Future<List<UserBookingView>> _loadHistory() async {
    final userManager = context.read<UserManager>();
    final userId = await userManager.getCurrentUserId();
    if (userId == null || userId.isEmpty) {
      throw BookingServiceException('Không tìm thấy thông tin người dùng.');
    }
    return _bookingService.listUserBookings(userId: userId);
  }

  Future<void> _refreshHistory() async {
    final future = _loadHistory();
    setState(() {
      _historyFuture = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử đặt sân'),
      ),
      body: FutureBuilder<List<UserBookingView>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildError(snapshot.error.toString());
          }

          final bookings = snapshot.data ?? const <UserBookingView>[];
          if (bookings.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: _refreshHistory,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final bookingView = bookings[index];
                return UserBookingTile(bookingView: bookingView);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _refreshHistory,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Icon(Icons.calendar_month, size: 72, color: Colors.grey),
          SizedBox(height: 12),
          Center(
            child: Text(
              'Bạn chưa có lịch sử đặt sân.',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return RefreshIndicator(
      onRefresh: _refreshHistory,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          const Icon(Icons.error_outline, size: 72, color: Colors.redAccent),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Kéo xuống để thử tải lại.',
              style: TextStyle(color: Colors.black45),
            ),
          ),
        ],
      ),
    );
  }
}
