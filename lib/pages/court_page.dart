import 'package:badminton_booking_app/components/my_court.dart';
import 'package:badminton_booking_app/components/my_text_field.dart';
import 'package:flutter/material.dart';

class CourtPage extends StatelessWidget {
  CourtPage({super.key});
  final TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Court Page'),
        centerTitle: true,
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                  top: 20, left: 12, right: 20, bottom: 10),
              child: MyTextfield(
                hintText: "Find your Court....",
                controller: controller,
                prefixIcon: Icon(Icons.search),
              ),
            ),
            MyCourt(),
            const SizedBox(height: 20),
            MyCourt(),
            const SizedBox(height: 20),
            MyCourt(),
            const SizedBox(height: 20),
            MyCourt(),
            const SizedBox(height: 20),
            MyCourt(),
            const SizedBox(height: 20),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
