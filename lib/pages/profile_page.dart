import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
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
          'User Profile Details',
          style: TextStyle(
            fontSize: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
