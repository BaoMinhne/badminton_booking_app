import 'package:flutter/material.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Search',
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
          'Search for courts, players, and more!',
          style: TextStyle(
            fontSize: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
