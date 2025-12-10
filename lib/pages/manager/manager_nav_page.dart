import 'package:flutter/material.dart';

import 'manager_dashboard_page.dart';
import 'manager_schedule_page.dart';
import 'manager_offline_booking_page.dart';
import 'manager_court_page.dart';
import 'manager_operating_hours_page.dart';
import 'manager_pricing_page.dart';
import 'manager_reports_page.dart';

class ManagerNavPage extends StatefulWidget {
  const ManagerNavPage({super.key});

  @override
  State<ManagerNavPage> createState() => _ManagerNavPageState();
}

class _ManagerNavPageState extends State<ManagerNavPage> {
  int _selectedIndex = 0;

  late final List<_ManagerTab> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      _ManagerTab(
        label: 'Dashboard',
        icon: Icons.dashboard_outlined,
        builder: (context) => const ManagerDashboardPage(),
      ),
      _ManagerTab(
        label: 'Lịch',
        icon: Icons.calendar_month_outlined,
        builder: (context) => const ManagerSchedulePage(),
      ),
      _ManagerTab(
        label: 'Booking offline',
        icon: Icons.phone_forwarded_outlined,
        builder: (context) => const ManagerOfflineBookingPage(),
      ),
      _ManagerTab(
        label: 'Sân & dịch vụ',
        icon: Icons.sports_tennis_outlined,
        builder: (context) => const ManagerCourtPage(),
      ),
      _ManagerTab(
        label: 'Giờ & slot',
        icon: Icons.schedule_outlined,
        builder: (context) => const ManagerOperatingHoursPage(),
      ),
      _ManagerTab(
        label: 'Giá sân',
        icon: Icons.price_change_outlined,
        builder: (context) => const ManagerPricingPage(),
      ),
      _ManagerTab(
        label: 'Báo cáo',
        icon: Icons.show_chart_outlined,
        builder: (context) => const ManagerReportsPage(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final currentTab = _tabs[_selectedIndex];
    final isWide = MediaQuery.of(context).size.width > 960;

    return Scaffold(
      appBar: AppBar(
        title: Text(currentTab.label),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () {
              setState(() {});
            },
          ),
        ],
      ),
      body: Row(
        children: [
          if (isWide) _buildSideRail(context),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: IndexedStack(
                index: _selectedIndex,
                children: _tabs
                    .map((tab) => Padding(
                          key: ValueKey(tab.label),
                          padding: const EdgeInsets.all(16),
                          child: tab.builder(context),
                        ))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isWide ? null : _buildBottomBar(context),
    );
  }

  Widget _buildSideRail(BuildContext context) {
    return NavigationRail(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) => setState(() => _selectedIndex = index),
      labelType: NavigationRailLabelType.all,
      destinations: _tabs
          .map(
            (tab) => NavigationRailDestination(
              icon: Icon(tab.icon),
              selectedIcon: Icon(tab.icon, color: Theme.of(context).primaryColor),
              label: Text(tab.label),
            ),
          )
          .toList(),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) => setState(() => _selectedIndex = index),
      destinations: _tabs
          .map(
            (tab) => NavigationDestination(
              icon: Icon(tab.icon),
              label: tab.label,
            ),
          )
          .toList(),
    );
  }
}

class _ManagerTab {
  final String label;
  final IconData icon;
  final WidgetBuilder builder;

  _ManagerTab({
    required this.label,
    required this.icon,
    required this.builder,
  });
}
