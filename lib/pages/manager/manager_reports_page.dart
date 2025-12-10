import 'package:flutter/material.dart';

class ManagerReportsPage extends StatelessWidget {
  const ManagerReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = [
      _ReportCard(title: 'Doanh thu hôm nay', value: '12.450.000₫', note: '+8% so với hôm qua'),
      _ReportCard(title: 'Tuần này', value: '86.200.000₫', note: '+12% WoW'),
      _ReportCard(title: 'Tháng này', value: '302.500.000₫', note: '+5% MoM'),
      _ReportCard(title: 'Tỷ lệ lấp đầy', value: '82%', note: 'Sân 2 cao nhất'),
    ];

    final bookings = [
      _BookingReportRow(customer: 'Nguyễn Minh', court: 'Sân 1', time: '06:00 - 07:30', channel: 'Online'),
      _BookingReportRow(customer: 'CLB Z', court: 'Sân 2', time: '18:00 - 20:00', channel: 'Offline'),
      _BookingReportRow(customer: 'Trần Thảo', court: 'Sân 3', time: '08:00 - 10:00', channel: 'Online'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Báo cáo & thống kê', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 900;
            final crossAxisCount = isWide ? 4 : 2;
            // Give cards more height on narrow screens to avoid vertical overflow.
            final aspectRatio = isWide ? 1.35 : 1.1;

            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: aspectRatio,
              children: stats,
            );
          },
        ),
        const SizedBox(height: 16),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('Danh sách booking đã thanh toán',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.download_outlined),
                      label: const Text('Export CSV'),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                ...bookings
                    .map(
                      (b) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.receipt_long_outlined),
                        title: Text(b.customer),
                        subtitle: Text('${b.court} • ${b.time}'),
                        trailing: Chip(
                          avatar: Icon(
                            b.channel == 'Online' ? Icons.wifi : Icons.phone_forwarded,
                            size: 16,
                          ),
                          label: Text(b.channel),
                        ),
                      ),
                    )
                    .toList(),
              ],
            ),
          ),
        )
      ],
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final String value;
  final String note;

  const _ReportCard({required this.title, required this.value, required this.note});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: colorScheme.secondaryContainer.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.trending_up, color: colorScheme.primary, size: 18),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    note,
                    style: TextStyle(color: colorScheme.primary),
                    softWrap: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingReportRow {
  final String customer;
  final String court;
  final String time;
  final String channel;

  _BookingReportRow({
    required this.customer,
    required this.court,
    required this.time,
    required this.channel,
  });
}
