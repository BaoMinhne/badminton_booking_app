import 'package:badminton_booking_app/components/my_court_time.dart';
import 'package:badminton_booking_app/models/court.dart';
import 'package:badminton_booking_app/models/court_booking.dart';
import 'package:badminton_booking_app/models/court_detail.dart';
import 'package:badminton_booking_app/pages/auth/auth_manager.dart';
import 'package:badminton_booking_app/pages/court/payment_page.dart';
import 'package:badminton_booking_app/services/court_booking_service.dart';
import 'package:badminton_booking_app/services/court_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BookingPage extends StatefulWidget {
  const BookingPage({
    super.key,
    required this.court,
    this.courtService,
    this.bookingService,
  });

  final Court court;
  final CourtService? courtService;
  final CourtBookingService? bookingService;

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  late DateTime _selectedDate;
  bool _isLoadingDetail = false;
  bool _isLoadingBookings = false;
  bool _isProcessing = false;
  String? _detailError;
  String? _bookingError;
  List<CourtUnit> _units = const [];
  List<CourtBooking> _bookings = const [];
  CourtBooking? _activeBooking;

  CourtService get _courtService => widget.courtService ?? CourtService();
  CourtBookingService get _bookingService =>
      widget.bookingService ?? CourtBookingService();

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadDetail();
  }

  Future<void> _selectDate() async {
    // đảm bảo initialDate nằm trong khoảng cho phép
    final first = DateTime(2025);
    final last = DateTime(2028);
    final init = _selectedDate.isBefore(first)
        ? first
        : (_selectedDate.isAfter(last) ? last : _selectedDate);

    final picked = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      await _loadBookings();
    }
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoadingDetail = true;
      _detailError = null;
    });

    try {
      final detail = await _courtService.getCourtDetail(widget.court.id);
      final activeUnits = detail.units.where((unit) => unit.isActive).toList();

      if (!mounted) return;
      setState(() {
        _units = activeUnits.isEmpty ? detail.units : activeUnits;
        _isLoadingDetail = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _detailError = _describeError(
          error,
          fallback: 'Không thể tải thông tin chi tiết của sân.',
        );
        _isLoadingDetail = false;
      });
    }

    await _loadBookings();
  }

  Future<void> _loadBookings() async {
    if (!mounted || _isLoadingBookings) return;

    setState(() {
      _isLoadingBookings = true;
      _bookingError = null;
    });

    try {
      final bookings = await _bookingService.listBookings(
        courtId: widget.court.id,
        date: _selectedDate,
      );
      if (mounted) {
        setState(() {
          _bookings = bookings;
          if (_activeBooking != null) {
            _activeBooking = bookings.firstWhere(
              (booking) => booking.id == _activeBooking!.id,
              orElse: () => _activeBooking!,
            );
          }
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _bookingError = _describeError(
          error,
          fallback: 'Không thể tải lịch đặt sân.',
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingBookings = false;
        });
      }
    }
  }

  Future<void> _holdSlot(CourtTimelineSlotTap slot) async {
    final auth = context.read<AuthManager>();
    final user = auth.user;
    if (user == null) {
      _showSnack('Vui lòng đăng nhập để đặt sân.');
      return;
    }

    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _bookingError = null;
    });

    try {
      final booking = await _bookingService.lockSlot(
        courtId: widget.court.id,
        courtUnitId: slot.courtUnitId,
        userId: user.id,
        startTime: slot.start,
        endTime: slot.end,
      );

      if (!mounted) return;

      setState(() {
        _activeBooking = booking;
      });

      await _loadBookings();
      _showSnack('Đã giữ chỗ trong 15 phút. Vui lòng xác nhận để gửi duyệt.');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _bookingError = _describeError(
          error,
          fallback: 'Không thể giữ chỗ cho khung giờ này.',
        );
      });
      _showSnack(_bookingError ?? 'Giữ chỗ thất bại.');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _confirmBooking() async {
    final booking = _activeBooking;
    if (booking == null || booking.status != CourtBookingStatus.locked) {
      return;
    }
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final updated = await _bookingService.confirmBooking(booking.id);
      if (!mounted) return;
      setState(() {
        _activeBooking = updated;
      });
      await _loadBookings();
      _showSnack('Đã gửi yêu cầu. Vui lòng chờ quản trị viên duyệt.');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _bookingError = _describeError(
          error,
          fallback: 'Không thể gửi yêu cầu đặt sân.',
        );
      });
      _showSnack(_bookingError ?? 'Không thể gửi yêu cầu.');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _cancelBooking() async {
    final booking = _activeBooking;
    if (booking == null) return;
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      await _bookingService.cancelBooking(booking.id);
      if (!mounted) return;
      setState(() {
        _activeBooking = null;
      });
      await _loadBookings();
      _showSnack('Đã hủy giữ chỗ.');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _bookingError = _describeError(
          error,
          fallback: 'Không thể hủy giữ chỗ.',
        );
      });
      _showSnack(_bookingError ?? 'Không thể hủy giữ chỗ.');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  String _describeError(Object error, {required String fallback}) {
    if (error is CourtServiceException) {
      return error.message;
    }
    if (error is CourtBookingServiceException) {
      return error.message;
    }
    final message = error.toString();
    if (message.isNotEmpty) return message;
    return fallback;
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final cs = Theme.of(context).colorScheme;
    final headerH = screenHeight / 4;
    final auth = context.watch<AuthManager>();
    final userId = auth.user?.id;

    return Scaffold(
      body: Stack(
        children: [
          // Tên Sân
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.only(top: screenHeight / 3.6, left: 10),
                  padding: const EdgeInsets.only(
                      top: 10, bottom: 10, left: 20, right: 20),
                  decoration: BoxDecoration(
                    color: cs.secondary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: cs.outline, width: 2),
                  ),
                  child: Text(
                    widget.court.name,
                    style: TextStyle(
                        fontSize: 18,
                        color: cs.onSecondary,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 20),
                if (_detailError != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildErrorBanner(cs, _detailError!, onRetry: _loadDetail),
                  ),
                if (_bookingError != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child:
                        _buildErrorBanner(cs, _bookingError!, onRetry: _loadBookings),
                  ),
                if (_isLoadingDetail)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (!_isLoadingDetail && _units.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Sân chưa có thông tin sân con để đặt lịch.',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                if (!_isLoadingDetail)
                  SizedBox(
                    height: screenHeight - headerH,
                    child: CourtTimeline(
                      startHour: 6,
                      endHour: 23,
                      slotWidth: 60,
                      rowHeight: 48,
                      courts: _units.isEmpty
                          ? ['Sân']
                          : List.generate(
                              _units.length,
                              (index) {
                                final unit = _units[index];
                                return unit.label.isNotEmpty
                                    ? unit.label
                                    : 'Sân ${index + 1}';
                              },
                            ),
                      courtUnitIds:
                          _units.isEmpty ? null : _units.map((u) => u.id).toList(),
                      reservations:
                          _buildReservations(userId: userId),
                      onSlotTap: _units.isEmpty ? null : _holdSlot,
                      day: _selectedDate,
                    ),
                  ),
                if (_isLoadingBookings)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Align(
                      alignment: Alignment.center,
                      child: CircularProgressIndicator(),
                    ),
                  ),
                if (_activeBooking != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildBookingSummary(cs, _activeBooking!),
                  ),
              ],
            ),
          ),
          // List CourtTimeline
          //

          // Title
          Container(
            height: screenHeight / 4,
            width: screenWidth,
            decoration: BoxDecoration(
              color: cs.primary,
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Text(
                    'B O O K I N G',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.only(right: 15),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: EdgeInsets.only(
                        top: 4,
                        bottom: 4,
                        left: 25,
                        right: 25,
                      ),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                              "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                              style: TextStyle(
                                color: cs.onSurface,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              )),
                          const SizedBox(width: 10),
                          GestureDetector(
                              onTap: () => _selectDate(),
                              child: Icon(Icons.calendar_month,
                                  color: cs.onSurface, size: 24)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const SizedBox(width: 15),
                    colorTile(
                      Colors.white,
                      "Trống",
                    ),
                    const SizedBox(width: 15),
                    colorTile(
                      Colors.red,
                      "Đã Đặt",
                    ),
                    const SizedBox(width: 15),
                    colorTile(
                      const Color(0xFFCFD8DC),
                      "Khóa",
                    ),
                  ],
                )
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            right: 16,
            child: SafeArea(
              child: GestureDetector(
                onTap: _resolvePrimaryAction() != null ? _resolvePrimaryAction() : null,
                child: Container(
                  padding: const EdgeInsets.only(
                      top: 12, bottom: 12, left: 20, right: 20),
                  decoration: BoxDecoration(
                    color: cs.secondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.outline, width: 2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_available,
                          color: cs.onSecondary, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        _resolvePrimaryActionLabel(),
                        style: TextStyle(
                          fontSize: 18,
                          color: cs.onSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top - 20,
            left: 8,
            child: SafeArea(
              child: IconButton(
                icon: Icon(Icons.arrow_back,
                    color: Theme.of(context).colorScheme.onPrimary, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget colorTile(
    Color color,
    String text,
  ) {
    return Row(
      children: [
        Container(
          width: 25,
          height: 25,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            fontSize: 15,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  List<CourtTimelineReservation> _buildReservations({String? userId}) {
    if (_units.isEmpty || _bookings.isEmpty) {
      return const [];
    }

    return _bookings
        .map(
          (booking) => CourtTimelineReservation(
            courtUnitId: booking.courtUnitId,
            start: booking.startTime,
            end: booking.endTime,
            status: booking.status,
            lockedUntil: booking.lockedUntil,
            isMine: booking.userId == userId,
          ),
        )
        .toList(growable: false);
  }

  Widget _buildErrorBanner(
    ColorScheme cs,
    String message, {
    Future<void> Function()? onRetry,
  }) {
    return Card(
      color: cs.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: cs.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: cs.onErrorContainer),
              ),
            ),
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                child: const Text('Thử lại'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingSummary(ColorScheme cs, CourtBooking booking) {
    final dateFormat = _formatDate(booking.startTime);
    final timeRange =
        '${_formatTime(booking.startTime)} - ${_formatTime(booking.endTime)}';
    final unitLabel = _units.firstWhere(
      (unit) => unit.id == booking.courtUnitId,
      orElse: () => CourtUnit(
        id: booking.courtUnitId,
        label: booking.courtUnitId,
        isActive: true,
      ),
    );

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Giữ chỗ của bạn',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text('Ngày: $dateFormat'),
            const SizedBox(height: 4),
            Text('Khung giờ: $timeRange'),
            const SizedBox(height: 4),
            Text('Sân: ${unitLabel.label.isNotEmpty ? unitLabel.label : unitLabel.id}'),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Trạng thái: ${_describeStatus(booking.status)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (booking.status == CourtBookingStatus.locked)
                  TextButton(
                    onPressed: _isProcessing ? null : _cancelBooking,
                    child: const Text('Hủy giữ chỗ'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _describeStatus(CourtBookingStatus status) {
    switch (status) {
      case CourtBookingStatus.locked:
        return 'Đang giữ chỗ';
      case CourtBookingStatus.pending:
        return 'Chờ duyệt';
      case CourtBookingStatus.confirmed:
        return 'Đã xác nhận';
      case CourtBookingStatus.cancelled:
        return 'Đã hủy';
    }
  }

  VoidCallback? _resolvePrimaryAction() {
    final booking = _activeBooking;
    if (booking == null) return null;

    if (booking.status == CourtBookingStatus.locked) {
      return _isProcessing ? null : _confirmBooking;
    }

    if (booking.status == CourtBookingStatus.confirmed) {
      return () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentPage(
              booking: booking,
              court: widget.court,
            ),
          ),
        );
      };
    }

    return null;
  }

  String _resolvePrimaryActionLabel() {
    final booking = _activeBooking;
    if (booking == null) {
      return 'Chọn khung giờ';
    }

    switch (booking.status) {
      case CourtBookingStatus.locked:
        return _isProcessing ? 'Đang xử lý...' : 'Gửi yêu cầu';
      case CourtBookingStatus.pending:
        return 'Đang chờ duyệt';
      case CourtBookingStatus.confirmed:
        return 'Thanh toán';
      case CourtBookingStatus.cancelled:
        return 'Chọn khung giờ';
    }
  }
}
