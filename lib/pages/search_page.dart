import 'package:badminton_booking_app/components/my_court.dart';
import 'package:badminton_booking_app/components/my_text_field.dart';
import 'package:flutter/material.dart';

class SearchPage extends StatelessWidget {
  SearchPage({super.key});

  final TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: screenHeight / 6,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Center(
                child: Text(
                  'Find Your Court',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          ),
          Container(
              margin: EdgeInsets.only(top: screenHeight / 10),
              padding: const EdgeInsets.only(top: 50, bottom: 40),
              child: ListView(
                children: [
                  MyCourt(),
                  MyCourt(),
                  MyCourt(),
                  MyCourt(),
                  MyCourt(),
                  MyCourt(),
                ],
              )),
          Container(
            margin: EdgeInsets.only(top: screenHeight / 22),
            padding:
                const EdgeInsets.only(top: 84, bottom: 40, right: 12, left: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyTextfield(
                  hintText: "Search for courts...",
                  controller: searchController,
                  prefixIcon: Icon(Icons.search),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
