import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/user_booking_tile.dart';
import '../../models/user_booking_view.dart';
import '../../services/booking_service.dart';
import 'user_manager.dart';

class UserTodayBookingsPage extends StatefulWidget {
  const UserTodayBookingsPage({super.key});

  @override
  State<UserTodayBookingsPage> createState() => _UserTodayBookingsPageState();
}

class _UserTodayBookingsPageState extends State<UserTodayBookingsPage> {
  final BookingService _bookingService = BookingService();
  Future<List<UserBookingView>>? _todayFuture;

  @override
  void initState() {
    super.initState();
    _todayFuture = _loadTodayBookings();
  }

  Future<List<UserBookingView>> _loadTodayBookings() async {
    final userManager = context.read<UserManager>();
    final userId = await userManager.getCurrentUserId();
    if (userId == null || userId.isEmpty) {
      throw BookingServiceException('Không tìm thấy thông tin người dùng.');
    }

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _bookingService.listUserBookings(
      userId: userId,
      startTimeInclusive: startOfDay,
      endTimeExclusive: endOfDay,
    );
  }

  Future<void> _refreshTodayBookings() async {
    final future = _loadTodayBookings();
    setState(() {
      _todayFuture = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch hôm nay'),
      ),
      body: FutureBuilder<List<UserBookingView>>(
        future: _todayFuture,
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
            onRefresh: _refreshTodayBookings,
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
      onRefresh: _refreshTodayBookings,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Icon(Icons.event_available, size: 72, color: Colors.grey),
          SizedBox(height: 12),
          Center(
            child: Text(
              'Bạn chưa có lịch nào trong hôm nay.',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return RefreshIndicator(
      onRefresh: _refreshTodayBookings,
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
