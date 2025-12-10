import 'package:flutter/material.dart';

class ManagerDashboardPage extends StatelessWidget {
  const ManagerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _KpiCard(title: 'Doanh thu hôm nay', value: '12.450.000₫', trend: '+8%'),
      _KpiCard(title: 'Tỷ lệ lấp đầy', value: '82%', trend: '+5%'),
      _KpiCard(title: 'Booking đã thanh toán', value: '46', trend: '+3%'),
      _KpiCard(title: 'Slot bị block', value: '2', trend: 'Sự kiện giải đấu'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        final crossAxisCount = isWide ? 4 : 2;

        return ListView(
          children: [
            const Text(
              'Tổng quan nhanh',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: cards,
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Lịch hôm nay',
              actionText: 'Xem chi tiết',
              onAction: () {},
              child: Column(
                children: const [
                  _ScheduleRow(
                    court: 'Sân 1',
                    time: '06:00 - 07:30',
                    customer: 'Nguyễn Minh',
                    status: 'Confirmed',
                    statusColor: Colors.green,
                  ),
                  _ScheduleRow(
                    court: 'Sân 2',
                    time: '08:00 - 10:00',
                    customer: 'Trần Thảo',
                    status: 'Offline',
                    statusColor: Colors.orange,
                  ),
                  _ScheduleRow(
                    court: 'Sân 3',
                    time: '10:00 - 12:00',
                    customer: 'CLB Đồng Đội',
                    status: 'Blocked',
                    statusColor: Colors.red,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Thông báo vận hành',
              actionText: 'Quản lý slot',
              onAction: () {},
              child: Column(
                children: const [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.warning_amber_outlined, color: Colors.orange),
                    title: Text('Sân 3 block 10:00 - 12:00 (Giải phong trào)'),
                    subtitle: Text('Ẩn với người dùng, chỉ hiển thị ở manager view'),
                  ),
                  Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.analytics_outlined),
                    title: Text('Tỷ lệ lấp đầy tuần này đạt 82%'),
                    subtitle: Text('Giảm 3% so với tuần trước'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String trend;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.primaryContainer.withOpacity(0.35),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.trending_up, color: colorScheme.primary, size: 18),
                const SizedBox(width: 6),
                Text(trend, style: TextStyle(color: colorScheme.primary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onAction;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (actionText != null)
                  TextButton(
                    onPressed: onAction,
                    child: Text(actionText!),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  final String court;
  final String time;
  final String customer;
  final String status;
  final Color statusColor;

  const _ScheduleRow({
    required this.court,
    required this.time,
    required this.customer,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(court, style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(time)),
          Expanded(child: Text(customer)),
          Chip(
            label: Text(status),
            side: BorderSide(color: statusColor.withOpacity(0.6)),
            backgroundColor: statusColor.withOpacity(0.1),
            labelStyle: TextStyle(color: statusColor),
          ),
        ],
      ),
    );
  }
}
