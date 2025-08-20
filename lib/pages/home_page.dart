import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Badminton Booking App'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Welcome to the Badminton Booking App!',
            ),
            ElevatedButton(
              onPressed: () {
                // Navigate to booking page
                Navigator.pushNamed(context, '/booking');
              },
              child: const Text('Book a Court'),
            ),
          ],
        ),
      ),
    );
  }
}
