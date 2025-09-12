import 'package:badminton_booking_app/components/my_court.dart';
import 'package:flutter/material.dart';

class CourtPage extends StatelessWidget {
  CourtPage({super.key});
  final TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'C O U R T',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        centerTitle: true,
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 5,
                  height: 24,
                  color: Theme.of(context).colorScheme.primary,
                  margin: const EdgeInsets.only(
                    left: 12,
                    right: 8,
                  ),
                ),
                Text(
                  "Có Thể Bạn Sẽ Thích",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  MyCourt(),
                  MyCourt(),
                  MyCourt(),
                  MyCourt(),
                  MyCourt(),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 5,
                  height: 24,
                  color: Theme.of(context).colorScheme.primary,
                  margin: const EdgeInsets.only(left: 12, right: 8),
                ),
                Text(
                  "Sân Gần Bạn",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  MyCourt(),
                  MyCourt(),
                  MyCourt(),
                  MyCourt(),
                  MyCourt(),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 5,
                  height: 24,
                  color: Theme.of(context).colorScheme.primary,
                  margin: const EdgeInsets.only(left: 12, right: 8),
                ),
                Text(
                  "Sân Phổ Biến",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  MyCourt(),
                  MyCourt(),
                  MyCourt(),
                  MyCourt(),
                  MyCourt(),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
