import 'package:badminton_booking_app/components/my_button.dart';
import 'package:badminton_booking_app/components/my_court_time.dart';
import 'package:badminton_booking_app/pages/payment_page.dart';
import 'package:flutter/material.dart';

class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  DateTime _selectedDate = DateTime.now();

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
// somewhere in your page:
    final start = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      7,
      0,
    );
    final end = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      22,
      0,
    );
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
                SizedBox(
                  height: screenHeight -
                      headerH, // cho CourtTimeline chiều cao hữu hạn
                  child: CourtTimeline(
                    startHour: 6,
                    endHour: 23,
                    slotWidth: 60,
                    rowHeight: 40,
                    courts: [
                      'Sân 1',
                      'Sân 2',
                      'Sân 3',
                      'Sân 4',
                      'Sân 5',
                    ],
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
                      Colors.grey,
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
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PaymentPage()),
                  );
                },
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
                        "Book Now",
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
}
