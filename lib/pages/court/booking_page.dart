import 'dart:async';

import 'package:badminton_booking_app/components/my_court_time.dart';
import 'package:badminton_booking_app/models/slot_reservation.dart';
import 'package:badminton_booking_app/pages/court/payment_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  static const int _timelineStartHour = 6;
  static const int _timelineEndHour = 23;
  DateTime _selectedDate = DateTime.now();
  final Map<String, _HeldSlotData> _heldSlots = {};

  List<String> get _courtNames => const [
        'Sân 1',
        'Sân 2',
        'Sân 3',
        'Sân 4',
        'Sân 5',
      ];

  @override
  void dispose() {
    for (final slot in _heldSlots.values) {
      slot.cancelTimer();
    }
    super.dispose();
  }

  SlotCellState? _buildSlotState(int courtIndex, int slotIndex) {
    final key = _slotKey(courtIndex, slotIndex);
    final hold = _heldSlots[key];
    if (hold == null) {
      return null;
    }
    return SlotCellState(
      status: hold.status,
      holdUntil: hold.status == SlotReservationStatus.holding
          ? hold.holdUntil
          : null,
    );
  }

  void _handleSlotTap(int courtIndex, int slotIndex) {
    final key = _slotKey(courtIndex, slotIndex);
    final current = _heldSlots[key];
    if (current != null) {
      if (current.status == SlotReservationStatus.holding) {
        _releaseSlot(key);
      }
      return;
    }

    final startHour = _timelineStartHour + slotIndex;
    final holdUntil = DateTime.now().add(const Duration(minutes: 15));
    final slot = _HeldSlotData(
      courtName: _courtNames[courtIndex],
      courtIndex: courtIndex,
      startHour: startHour,
      holdUntil: holdUntil,
      status: SlotReservationStatus.holding,
      onExpired: () {
        if (mounted) {
          setState(() {
            _heldSlots.remove(key);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Hết thời gian giữ chỗ ${_courtNames[courtIndex]} ${_hourLabel(startHour)}'),
            ),
          );
        }
      },
    );

    slot.startTimer();

    setState(() {
      _heldSlots[key] = slot;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Đang giữ chỗ ${slot.courtName} ${_hourLabel(slot.startHour)} trong 15 phút'),
      ),
    );
  }

  String _hourLabel(int hour) => '${hour.toString().padLeft(2, '0')}:00';

  void _releaseSlot(String key) {
    final slot = _heldSlots.remove(key);
    slot?.cancelTimer();
    if (slot != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Đã hủy giữ chỗ ${slot.courtName} ${_hourLabel(slot.startHour)}'),
        ),
      );
      setState(() {});
    }
  }

  String _slotKey(int courtIndex, int slotIndex) => '$courtIndex-$slotIndex';

  Future<List<SlotReservationInfo>> _confirmPayment() async {
    final updates = <SlotReservationInfo>[];
    setState(() {
      _heldSlots.updateAll((key, slot) {
        slot.cancelTimer();
        slot.status = SlotReservationStatus.awaitingApproval;
        updates.add(slot.toInfo());
        return slot;
      });
    });
    return updates;
  }

  void _handlePaymentNavigation() {
    if (_heldSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất 1 khung giờ.')),
      );
      return;
    }

    final infoList = _heldSlots.values.map((slot) => slot.toInfo()).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPage(
          holds: infoList,
          onConfirmPayment: _confirmPayment,
          onPayNow: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Vui lòng thanh toán theo hướng dẫn.')),
            );
          },
        ),
      ),
    ).then((_) {
      setState(() {});
    });
  }

  Widget _holdingBanner(ColorScheme cs) {
    final format = DateFormat('HH:mm');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Khung giờ đang giữ (${_heldSlots.length})',
            style: TextStyle(
              color: cs.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _heldSlots.values.map((slot) {
              final status = slot.status;
              final String label;
              if (status == SlotReservationStatus.awaitingApproval) {
                label = 'Chờ admin duyệt';
              } else if (slot.holdUntil != null) {
                label = 'Giữ đến ${format.format(slot.holdUntil!)}';
              } else {
                label = 'Đang giữ chỗ';
              }
              return Chip(
                backgroundColor: slotStatusBackground(status, cs),
                side: BorderSide(color: slotStatusBorder(status, cs)),
                label: Text(
                  '${slot.courtName} ${_hourLabel(slot.startHour)} • $label',
                  style: TextStyle(color: cs.onSurface),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final cs = Theme.of(context).colorScheme;
    final headerH = screenHeight / 4;

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
                    "Sân Cầu Lông Minh Nghĩa",
                    style: TextStyle(
                        fontSize: 18,
                        color: cs.onSecondary,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 20),
                if (_heldSlots.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _holdingBanner(cs),
                  ),
                SizedBox(height: _heldSlots.isNotEmpty ? 16 : 0),
                SizedBox(
                  height: screenHeight -
                      headerH, // cho CourtTimeline chiều cao hữu hạn
                  child: CourtTimeline(
                    startHour: _timelineStartHour,
                    endHour: _timelineEndHour,
                    slotWidth: 60,
                    rowHeight: 40,
                    courts: _courtNames,
                    slotStateResolver: _buildSlotState,
                    onSlotTap: _handleSlotTap,
                  ),
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      colorTile(
                        slotStatusBackground(null, cs),
                        slotStatusBorder(null, cs),
                        "Trống",
                        cs.onSurface,
                      ),
                      colorTile(
                        slotStatusBackground(
                            SlotReservationStatus.booked, cs),
                        slotStatusBorder(SlotReservationStatus.booked, cs),
                        "Đã Đặt",
                        cs.onSurface,
                      ),
                      colorTile(
                        slotStatusBackground(
                            SlotReservationStatus.locked, cs),
                        slotStatusBorder(SlotReservationStatus.locked, cs),
                        "Khóa",
                        cs.onSurface,
                      ),
                      colorTile(
                        slotStatusBackground(
                            SlotReservationStatus.holding, cs),
                        slotStatusBorder(SlotReservationStatus.holding, cs),
                        "Đang giữ (15')",
                        cs.onSurface,
                      ),
                      colorTile(
                        slotStatusBackground(
                            SlotReservationStatus.awaitingApproval, cs),
                        slotStatusBorder(
                            SlotReservationStatus.awaitingApproval, cs),
                        "Chờ duyệt",
                        cs.onSurface,
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            right: 16,
            child: SafeArea(
              child: GestureDetector(
                onTap: _heldSlots.isNotEmpty ? _handlePaymentNavigation : null,
                child: Opacity(
                  opacity: _heldSlots.isNotEmpty ? 1 : 0.5,
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
                          _heldSlots.isNotEmpty
                              ? "Book Now (${_heldSlots.length})"
                              : "Chọn khung giờ",
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
    Color fillColor,
    Color borderColor,
    String text,
    Color textColor,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 25,
          height: 25,
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: borderColor, width: 1.5),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            fontSize: 15,
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _HeldSlotData {
  _HeldSlotData({
    required this.courtName,
    required this.courtIndex,
    required this.startHour,
    required this.holdUntil,
    required this.status,
    required this.onExpired,
  });

  final String courtName;
  final int courtIndex;
  final int startHour;
  DateTime? holdUntil;
  SlotReservationStatus status;
  final VoidCallback onExpired;
  Timer? _timer;

  void startTimer() {
    final until = holdUntil;
    if (until == null) return;
    cancelTimer();
    final duration = until.difference(DateTime.now());
    if (duration.isNegative) {
      onExpired();
      return;
    }
    _timer = Timer(duration, onExpired);
  }

  void cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  SlotReservationInfo toInfo() {
    return SlotReservationInfo(
      courtName: courtName,
      courtIndex: courtIndex,
      startHour: startHour,
      status: status,
      holdUntil: holdUntil,
    );
  }
}
