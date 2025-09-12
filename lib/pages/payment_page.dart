import 'package:flutter/material.dart';

class PaymentPage extends StatelessWidget {
  const PaymentPage({super.key});

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
                  // Other widgets can be added here
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
}
