import 'package:flutter/material.dart';

class NortiPage extends StatelessWidget {
  const NortiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          'No notifications yet!',
          style: TextStyle(
            fontSize: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
