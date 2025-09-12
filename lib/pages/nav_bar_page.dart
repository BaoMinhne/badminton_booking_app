import 'package:badminton_booking_app/pages/booking_page.dart';
import 'package:badminton_booking_app/pages/court_page.dart';
import 'package:badminton_booking_app/pages/home_page.dart';
import 'package:badminton_booking_app/pages/profile_page.dart';
import 'package:badminton_booking_app/pages/social_page.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';

class NavBarPage extends StatefulWidget {
  const NavBarPage({super.key});

  @override
  State<NavBarPage> createState() => _NavBarPageState();
}

class _NavBarPageState extends State<NavBarPage> {
  int _index = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(),
      SocialPage(),
      BookingPage(),
      CourtPage(),
      ProfilePage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final int safeIndex = _index.clamp(0, _pages.length - 1);

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: safeIndex, children: _pages),
      bottomNavigationBar: CurvedNavigationBar(
        index: safeIndex,
        onTap: (i) => setState(() => _index = i),
        backgroundColor: Colors.transparent,
        color: Theme.of(context).colorScheme.primary,
        height: 70, // Tăng chiều cao để hiển thị rõ hơn
        animationDuration: const Duration(milliseconds: 300),
        items: const [
          Icon(Icons.home, size: 30, color: Colors.white), // HomePage
          Icon(Icons.south_america,
              size: 30, color: Colors.white), // SearchPage
          Icon(Icons.book_online_rounded,
              size: 30, color: Colors.white), // NortiPage
          Icon(Icons.sports_tennis_outlined, size: 30, color: Colors.white),
          Icon(Icons.person, size: 30, color: Colors.white), // ProfilePage
        ],
      ),
    );
  }
}
