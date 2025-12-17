import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../services/manager_reports_service.dart';

class ManagerReportsPage extends StatefulWidget {
  const ManagerReportsPage({super.key});

  @override
  State<ManagerReportsPage> createState() => _ManagerReportsPageState();
}

class _ManagerReportsPageState extends State<ManagerReportsPage> {
  final _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  final _service = ManagerReportsService();

  ReportRange _selectedRange = ReportRange.today;
  _ReportSnapshot? _snapshot;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRange(_selectedRange);
  }

  Future<void> _loadRange(ReportRange range) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _service.fetchReport(range);
      setState(() {
        _selectedRange = range;
        _snapshot = _ReportSnapshot.fromService(data);
        _loading = false;
      });
    } catch (error) {
      setState(() {
        _loading = false;
        _error = _extractErrorMessage(error);
      });
    }
  }

  String _extractErrorMessage(Object error) {
    if (error is ClientException) {
      final message = error.response['message'];
      if (message is String && message.isNotEmpty) return message;
    }
    return 'Không thể tải dữ liệu báo cáo. Vui lòng thử lại sau.';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => _loadRange(_selectedRange),
              child: const Text('Thử lại'),
            )
          ],
        ),
      );
    }

    final snapshot = _snapshot ?? _ReportSnapshot.empty();
    final isWide = MediaQuery.of(context).size.width > 900;
    final crossAxisCount = isWide ? 4 : 2;
    final horizontalSpacing = 2.0;
    final cardHeight = isWide ? 210.0 : 230.0;

    final kpiCards = [
      _ReportCard(
        icon: Icons.attach_money,
        title: 'Doanh thu hôm nay',
        value: _currencyFormat.format(snapshot.todayRevenueMinor),
        note: _buildChangeNote(snapshot.todayRevenueChange, 'so với hôm qua'),
      ),
      _ReportCard(
        icon: Icons.calendar_today,
        title: 'Tuần này',
        value: _currencyFormat.format(snapshot.weekRevenueMinor),
        note: _buildChangeNote(snapshot.weekRevenueChange, 'WoW'),
      ),
      _ReportCard(
        icon: Icons.calendar_month,
        title: 'Tháng này',
        value: _currencyFormat.format(snapshot.monthRevenueMinor),
        note: _buildChangeNote(snapshot.monthRevenueChange, 'MoM'),
      ),
      _ReportCard(
        icon: Icons.pie_chart,
        title: 'Tỷ lệ lấp đầy',
        value: '${(snapshot.occupancyRate * 100).toStringAsFixed(0)}%',
        note: _buildChangeNote(snapshot.occupancyChange, 'Sân 2 cao nhất'),
      ),
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: 0, // hoặc 4
        vertical: 16,
      ),
      children: [
        Row(
          children: [
            Wrap(
              spacing: 8,
              children: ReportRange.values
                  .map(
                    (range) => ChoiceChip(
                      label: Text(range.label),
                      selected: _selectedRange == range,
                      onSelected: (_) => _loadRange(range),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: kpiCards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: horizontalSpacing,
            mainAxisSpacing: 12,
            mainAxisExtent: cardHeight,
          ),
          itemBuilder: (context, index) => kpiCards[index],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final chartsAreSideBySide = constraints.maxWidth > 900;
            if (chartsAreSideBySide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _ChartCard(
                      title: 'Doanh thu theo thời gian',
                      subtitle: 'Biểu đồ đường thể hiện xu hướng doanh thu',
                      child: _RevenueLineChart(points: snapshot.revenueTrend),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: _ChartCard(
                      title: 'Tỷ lệ lấp đầy theo sân',
                      subtitle: 'So sánh nhanh giữa các sân',
                      child:
                          _OccupancyBarChart(points: snapshot.occupancyByCourt),
                    ),
                  ),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ChartCard(
                  title: 'Doanh thu theo thời gian',
                  subtitle: 'Biểu đồ đường thể hiện xu hướng doanh thu',
                  child: _RevenueLineChart(points: snapshot.revenueTrend),
                ),
                const SizedBox(height: 16),
                _ChartCard(
                  title: 'Tỷ lệ lấp đầy theo sân',
                  subtitle: 'So sánh nhanh giữa các sân',
                  child: _OccupancyBarChart(points: snapshot.occupancyByCourt),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isRow = constraints.maxWidth > 900;
            if (isRow) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: _ChartCard(
                      title: 'Kênh đặt sân',
                      subtitle: 'Tỷ trọng giữa online và offline',
                      child: _ChannelPieChart(stats: snapshot.channelBreakdown),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: _BookingsCard(bookings: snapshot.bookings),
                  ),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ChartCard(
                  title: 'Kênh đặt sân',
                  subtitle: 'Tỷ trọng giữa online và offline',
                  child: _ChannelPieChart(stats: snapshot.channelBreakdown),
                ),
                const SizedBox(height: 16),
                _BookingsCard(bookings: snapshot.bookings),
              ],
            );
          },
        ),
      ],
    );
  }

  String _buildChangeNote(double delta, String suffix) {
    final sign = delta >= 0 ? '+' : '-';
    final percent = (delta.abs() * 100).toStringAsFixed(0);
    return '$sign$percent% $suffix';
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            SizedBox(height: 240, child: child),
          ],
        ),
      ),
    );
  }
}

class _BookingsCard extends StatelessWidget {
  final List<_BookingReportRow> bookings;

  const _BookingsCard({required this.bookings});

  @override
  Widget build(BuildContext context) {
    return Card(
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
                        b.channel == 'Online'
                            ? Icons.wifi
                            : Icons.phone_forwarded,
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
    );
  }
}

class _ReportCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String note;

  const _ReportCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.note,
  });

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
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: colorScheme.primary.withOpacity(0.1),
                  child: Icon(icon, color: colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(value,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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

class _RevenueLineChart extends StatelessWidget {
  final List<_ChartPoint> points;

  const _RevenueLineChart({required this.points});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (points.length - 1).toDouble(),
        minY: 0,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, _) {
                final index = value.toInt();
                if (index < 0 || index >= points.length)
                  return const SizedBox.shrink();
                return Text(points[index].label);
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 46,
              interval: _computeInterval(points.map((e) => e.value).toList()),
              getTitlesWidget: (value, _) =>
                  Text('${value.toStringAsFixed(0)}tr'),
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
            show: true, drawVerticalLine: false, horizontalInterval: 5),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            spots: [
              for (int i = 0; i < points.length; i++)
                FlSpot(i.toDouble(), points[i].value),
            ],
            barWidth: 4,
            color: color,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: color.withOpacity(0.15),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots
                .map(
                  (spot) => LineTooltipItem(
                    '${points[spot.spotIndex].label}\n',
                    const TextStyle(fontWeight: FontWeight.bold),
                    children: [
                      TextSpan(text: '${spot.y.toStringAsFixed(1)} triệu')
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _OccupancyBarChart extends StatelessWidget {
  final List<_CourtOccupancy> points;

  const _OccupancyBarChart({required this.points});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return BarChart(
      BarChartData(
        maxY: 1,
        minY: 0,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, _, rod, __) => BarTooltipItem(
              '${points[group.x.toInt()].label}\n',
              const TextStyle(fontWeight: FontWeight.bold),
              children: [
                TextSpan(text: '${(rod.toY * 100).toStringAsFixed(0)}%')
              ],
            ),
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 0.2,
              getTitlesWidget: (value, _) => Text('${(value * 100).round()}%'),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                final index = value.toInt();
                if (index < 0 || index >= points.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(points[index].label),
                );
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
            show: true, drawVerticalLine: false, horizontalInterval: 0.2),
        borderData: FlBorderData(show: false),
        barGroups: [
          for (int i = 0; i < points.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: points[i].rate,
                  width: 26,
                  borderRadius: BorderRadius.circular(6),
                  color: primary,
                  backDrawRodData: BackgroundBarChartRodData(
                      show: true, toY: 1, color: Colors.grey.shade200),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ChannelPieChart extends StatelessWidget {
  final List<_ChannelStat> stats;

  const _ChannelPieChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final total = stats.fold<int>(0, (sum, e) => sum + e.count);
    final sections = stats.asMap().entries.map((entry) {
      final color =
          entry.key == 0 ? colorScheme.primary : colorScheme.secondary;
      final percentage = total == 0 ? 0 : (entry.value.count / total * 100);
      return PieChartSectionData(
        color: color,
        value: entry.value.count.toDouble(),
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 70,
        titleStyle:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      );
    }).toList();

    return Column(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: sections,
              sectionsSpace: 2,
              centerSpaceRadius: 32,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: stats.asMap().entries.map((entry) {
            final color =
                entry.key == 0 ? colorScheme.primary : colorScheme.secondary;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Container(
                      width: 12,
                      height: 12,
                      decoration:
                          BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('${entry.value.label} (${entry.value.count})'),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ChartPoint {
  final String label;
  final double value;

  const _ChartPoint(this.label, this.value);
}

class _CourtOccupancy {
  final String label;
  final double rate;

  const _CourtOccupancy(this.label, this.rate);
}

class _ChannelStat {
  final String label;
  final int count;

  const _ChannelStat(this.label, this.count);
}

class _BookingReportRow {
  final String customer;
  final String court;
  final String time;
  final String channel;

  const _BookingReportRow({
    required this.customer,
    required this.court,
    required this.time,
    required this.channel,
  });
}

class _ReportSnapshot {
  final int todayRevenueMinor;
  final double todayRevenueChange;
  final int weekRevenueMinor;
  final double weekRevenueChange;
  final int monthRevenueMinor;
  final double monthRevenueChange;
  final double occupancyRate;
  final double occupancyChange;
  final List<_ChartPoint> revenueTrend;
  final List<_CourtOccupancy> occupancyByCourt;
  final List<_ChannelStat> channelBreakdown;
  final List<_BookingReportRow> bookings;

  const _ReportSnapshot({
    required this.todayRevenueMinor,
    required this.todayRevenueChange,
    required this.weekRevenueMinor,
    required this.weekRevenueChange,
    required this.monthRevenueMinor,
    required this.monthRevenueChange,
    required this.occupancyRate,
    required this.occupancyChange,
    required this.revenueTrend,
    required this.occupancyByCourt,
    required this.channelBreakdown,
    required this.bookings,
  });

  factory _ReportSnapshot.fromService(ManagerReportSnapshot data) {
    return _ReportSnapshot(
      todayRevenueMinor: data.todayRevenueMinor,
      todayRevenueChange: data.todayRevenueChange,
      weekRevenueMinor: data.weekRevenueMinor,
      weekRevenueChange: data.weekRevenueChange,
      monthRevenueMinor: data.monthRevenueMinor,
      monthRevenueChange: data.monthRevenueChange,
      occupancyRate: data.occupancyRate,
      occupancyChange: data.occupancyChange,
      revenueTrend:
          data.revenueTrend.map((p) => _ChartPoint(p.label, p.value)).toList(),
      occupancyByCourt: data.occupancyByCourt
          .map((o) => _CourtOccupancy(o.label, o.rate))
          .toList(),
      channelBreakdown: data.channelBreakdown
          .map((c) => _ChannelStat(c.label, c.count))
          .toList(),
      bookings: data.bookings
          .map(
            (b) => _BookingReportRow(
              customer: b.customer,
              court: b.court,
              time: b.time,
              channel: b.channel,
            ),
          )
          .toList(),
    );
  }

  const _ReportSnapshot.empty()
      : todayRevenueMinor = 0,
        todayRevenueChange = 0,
        weekRevenueMinor = 0,
        weekRevenueChange = 0,
        monthRevenueMinor = 0,
        monthRevenueChange = 0,
        occupancyRate = 0,
        occupancyChange = 0,
        revenueTrend = const [],
        occupancyByCourt = const [],
        channelBreakdown = const [],
        bookings = const [];
}

extension on ReportRange {
  String get label {
    switch (this) {
      case ReportRange.today:
        return 'Hôm nay';
      case ReportRange.week:
        return '7 ngày';
      case ReportRange.month:
        return '30 ngày';
    }
  }
}

double _computeInterval(List<double> values) {
  if (values.isEmpty) return 1;
  final max = values.reduce((a, b) => a > b ? a : b);
  final rough = (max / 3).clamp(1, double.infinity);
  if (rough < 5) return 5;
  if (rough < 10) return 10;
  return 20;
}
