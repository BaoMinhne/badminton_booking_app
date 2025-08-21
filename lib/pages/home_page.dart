import 'package:badminton_booking_app/components/my_button.dart';
import 'package:badminton_booking_app/components/my_text_field.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});
  final TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Courtify Home'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Welcome to the Badminton Booking App!',
            ),
            const SizedBox(height: 20),
            MyTextfield(
              hintText: "Email",
              controller: controller,
              prefixIcon: Icon(Icons.person),
            ),
            MyTextfield(
              hintText: "Password",
              controller: controller,
              obscureText: true,
              prefixIcon: Icon(Icons.password),
            ),
            MyButton(
              text: "Đăng Nhập",
            ),
          ],
        ),
      ),
    );
  }
}
