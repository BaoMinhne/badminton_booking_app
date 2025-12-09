import 'package:badminton_booking_app/pages/court/booking_page.dart';
import 'package:badminton_booking_app/pages/court/court_page.dart';
import 'package:badminton_booking_app/pages/home/home_page.dart';
import 'package:badminton_booking_app/pages/user/profile_page.dart';
import 'package:badminton_booking_app/pages/social/social_page.dart';
import 'package:badminton_booking_app/pages/user/user_manager.dart';
import 'package:badminton_booking_app/pages/user/onboarding_page.dart';
import 'package:badminton_booking_app/models/user_details.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NavBarPage extends StatefulWidget {
  const NavBarPage({super.key});

  @override
  State<NavBarPage> createState() => _NavBarPageState();
}

class _NavBarPageState extends State<NavBarPage> {
  int _index = 0;
  bool _checkingOnboarding = false;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadAndCheckOnboarding();
    });

    _pages = [
      HomePage(),
      SocialPage(),
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
          // NortiPage
          Icon(Icons.book_online_outlined, size: 30, color: Colors.white),
          Icon(Icons.person, size: 30, color: Colors.white), // ProfilePage
        ],
      ),
    );
  }

  Future<void> _loadAndCheckOnboarding() async {
    final userManager = context.read<UserManager>();
    await userManager.loadMe();
    if (!mounted) return;
    await _checkOnboarding(userManager);
  }

  Future<void> _checkOnboarding(UserManager userManager) async {
    if (_checkingOnboarding) return;
    _checkingOnboarding = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = await userManager.getCurrentUserId();
      if (userId == null) return;

      UserDetails? details = userManager.myDetails;
      details ??= await userManager.getByUserId(userId);
      if (details == null) return;

      final hasCompleted =
          prefs.getBool('onboarded_${details.userId}') ?? false;
      final needsOnboarding =
          !hasCompleted || _isProfileIncomplete(details);

      if (needsOnboarding) {
        final completed = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => OnboardingPage(initialDetails: details!),
          ),
        );

        if (completed == true) {
          await userManager.refreshMyDetails();
          await prefs.setBool('onboarded_${details.userId}', true);
        }
      }
    } catch (_) {
      // Bỏ qua lỗi onboarding để không chặn luồng chính
    } finally {
      _checkingOnboarding = false;
    }
  }

  bool _isProfileIncomplete(UserDetails? details) {
    if (details == null) return true;

    bool isNullOrEmpty(String? value) => value == null || value.trim().isEmpty;

    return isNullOrEmpty(details.fullname) ||
        isNullOrEmpty(details.level) ||
        details.matchTypes.isEmpty ||
        details.playStyleTags.isEmpty ||
        isNullOrEmpty(details.preferredRoleDoubles) ||
        isNullOrEmpty(details.intensity) ||
        details.experienceYears == null ||
        details.playsPerWeek == null ||
        isNullOrEmpty(details.gender) ||
        details.birthday == null;
  }
}
