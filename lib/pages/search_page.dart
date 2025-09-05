import 'package:badminton_booking_app/components/my_court.dart';
import 'package:badminton_booking_app/components/my_text_field.dart';
import 'package:flutter/material.dart';

class SearchPage extends StatelessWidget {
  SearchPage({super.key});

  final TextEditingController searchController = TextEditingController();

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
                  'S E A R C H',
                  style: TextStyle(
                    fontSize: 24,
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
                  size: 30,
                ),
              ),
            ),
          ),

          // Search Bar
          Container(
            margin: EdgeInsets.only(top: screenHeight / 38),
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
