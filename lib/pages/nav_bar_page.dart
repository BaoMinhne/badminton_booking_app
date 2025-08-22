import 'package:badminton_booking_app/pages/home_page.dart';
import 'package:badminton_booking_app/pages/norti_page.dart';
import 'package:badminton_booking_app/pages/profile_page.dart';
import 'package:badminton_booking_app/pages/search_page.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';

class NavBarPage extends StatefulWidget {
  const NavBarPage({super.key});

  @override
  State<NavBarPage> createState() => _NavBarPageState();
}

class _NavBarPageState extends State<NavBarPage> {
  int _index = 0;

  final List<Widget> _pages = [
    HomePage(),
    const SearchPage(),
    const NortiPage(),
    const ProfilePage(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: CurvedNavigationBar(
        index: _index,
        onTap: (i) => setState(() => _index = i),
        backgroundColor: Colors.transparent,
        color: Theme.of(context).colorScheme.primary,
        animationDuration: const Duration(milliseconds: 300),
        items: [
          Icon(Icons.home, size: 30, color: Colors.white),
          Icon(Icons.search, size: 30, color: Colors.white),
          Icon(Icons.notifications, size: 30, color: Colors.white),
          Icon(Icons.person, size: 30, color: Colors.white),
        ],
      ),
    );
  }
}
