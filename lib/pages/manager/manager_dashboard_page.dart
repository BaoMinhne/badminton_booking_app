import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/booking.dart';
import '../../services/manager_dashboard_service.dart';

class ManagerDashboardPage extends StatefulWidget {
  const ManagerDashboardPage({super.key});

  @override
  State<ManagerDashboardPage> createState() => _ManagerDashboardPageState();
}

class _ManagerDashboardPageState extends State<ManagerDashboardPage> {
  final _service = ManagerDashboardService();
  final _realtimeService = ManagerDashboardRealtimeService();
  late Future<ManagerDashboardData> _future;
  DateTime _selectedDate = DateTime.now();
  bool _isRealtimeRefreshing = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<ManagerDashboardData> _load() async {
    final date = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final data = await _service.fetchDashboardData(date);
    await _realtimeService.subscribe(
      date: date,
      courtIds: data.today.courtIds,
      bookingIds: data.today.bookingIds,
      onChange: _handleRealtimeChange,
    );
    return data;
  }

  Future<void> _refresh() async {
    final future = _load();
    setState(() {
      _future = future;
    });
    await future;
  }

  void _handleRealtimeChange() {
    if (!mounted || _isRealtimeRefreshing) return;
    _isRealtimeRefreshing = true;
    unawaited(
      _refresh().whenComplete(() {
        if (mounted) {
          _isRealtimeRefreshing = false;
        }
      }),
    );
  }

  void _changeDay(int delta) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: delta));
      _future = _load();
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('vi'),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
        _future = _load();
      });
    }
  }

  @override
  void dispose() {
    unawaited(_realtimeService.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ManagerDashboardData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh_outlined),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data;
        if (data == null || !data.hasCourts) {
          return const Center(
            child: Text('You do not have any courts to display statistics.'),
          );
        }

        final today = data.today;
        final previous = data.previous;

        final currencyFormat = NumberFormat.currency(
          locale: 'vi_VN',
          symbol: '₫',
          decimalDigits: 0,
        );

        final kpiCards = [
          _KpiCard(
            title: 'Today revenue',
            value: currencyFormat.format(today.revenueMinor),
            trend: _buildTrend(today.revenueMinor, previous?.revenueMinor),
          ),
          _KpiCard(
            title: 'Occupancy rate',
            value: '${(today.occupancyRate * 100).toStringAsFixed(0)}%',
            trend: _buildTrend(
              (today.occupancyRate * 100).round(),
              previous == null ? null : (previous.occupancyRate * 100).round(),
            ),
          ),
          _KpiCard(
            title: 'Paid bookings',
            value: '${today.confirmedBookingCount}',
            trend: _buildTrend(
              today.confirmedBookingCount,
              previous?.confirmedBookingCount,
            ),
          ),
          _KpiCard(
            title: 'Awaiting payment',
            value: '${today.awaitingPaymentCount}',
            trend: _buildTrend(
              today.awaitingPaymentCount,
              previous?.awaitingPaymentCount,
            ),
          ),
        ];

        return RefreshIndicator(
          onRefresh: _refresh,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;
              final crossAxisCount = isWide ? 4 : 2;
              final horizontalSpacing = 12.0;
              final availableWidth = constraints.maxWidth -
                  (crossAxisCount - 1) * horizontalSpacing;
              final cardWidth = availableWidth / crossAxisCount;
              final targetHeight = isWide ? 140.0 : 170.0;
              final childAspectRatio = cardWidth / targetHeight;

              final scheduleItems = today.schedule.take(5).toList();
              final blockedNotices = today.schedule
                  .where((item) => item.status == BookingStatus.held)
                  .toList();

              return ListView(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => _changeDay(-1),
                        tooltip: 'Previous day',
                      ),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickDate,
                          icon: const Icon(Icons.calendar_today_outlined),
                          label: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => _changeDay(1),
                        tooltip: 'Next day',
                      ),
                      const SizedBox(width: 4),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedDate = DateTime.now();
                            _future = _load();
                          });
                        },
                        child: const Text('Today'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Quick overview',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: horizontalSpacing,
                    mainAxisSpacing: 12,
                    childAspectRatio: childAspectRatio,
                    children: kpiCards,
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Today schedule',
                    actionText: 'View details',
                    onAction: _refresh,
                    child: Column(
                      children: scheduleItems.isEmpty
                          ? const [
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text('No schedule for today yet'),
                              )
                            ]
                          : scheduleItems
                              .map(
                                (item) => _ScheduleRow(
                                  court: item.courtLabel,
                                  time:
                                      '${DateFormat('HH:mm').format(item.startTime)} - ${DateFormat('HH:mm').format(item.endTime)}',
                                  customer: item.customerName,
                                  status: _statusLabel(item.status),
                                  statusColor: _statusColor(item.status, context),
                                ),
                              )
                              .toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Operations notices',
                    actionText: 'Manage slots',
                    onAction: _refresh,
                    child: Column(
                      children: blockedNotices.isEmpty
                          ? const [
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(Icons.analytics_outlined),
                                title: Text('No blocked slots today'),
                                subtitle: Text('Blocked slots will include a reason'),
                              ),
                            ]
                          : blockedNotices
                              .map(
                                (item) => Column(
                                  children: [
                                    ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: const Icon(
                                        Icons.warning_amber_outlined,
                                        color: Colors.orange,
                                      ),
                                      title: Text(
                                        '${item.courtLabel} block ${DateFormat('HH:mm').format(item.startTime)} - ${DateFormat('HH:mm').format(item.endTime)}',
                                      ),
                                      subtitle: Text(
                                        item.note?.isNotEmpty == true
                                            ? item.note!
                                            : 'Hidden from customers, shown only in manager view',
                                      ),
                                    ),
                                    const Divider(height: 1),
                                  ],
                                ),
                              )
                              .toList(),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  _Trend _buildTrend(num current, num? previous) {
    if (previous == null) return const _Trend(label: '—', color: Colors.grey);
    if (previous == 0) {
      return _Trend(
        label: current == 0 ? '0%' : '+∞%',
        color: Colors.green,
      );
    }
    final deltaPercent = ((current - previous) / previous) * 100;
    final icon = deltaPercent >= 0 ? Icons.trending_up : Icons.trending_down;
    final color = deltaPercent >= 0 ? Colors.green : Colors.red;
    final label = '${deltaPercent >= 0 ? '+' : ''}${deltaPercent.toStringAsFixed(1)}%';
    return _Trend(label: label, color: color, icon: icon);
  }

  String _statusLabel(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return 'Online';
      case BookingStatus.awaitingPayment:
        return 'Awaiting payment';
      case BookingStatus.held:
        return 'Blocked';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.expired:
        return 'Expired';
    }
  }

  Color _statusColor(BookingStatus status, BuildContext context) {
    switch (status) {
      case BookingStatus.confirmed:
        return Colors.green;
      case BookingStatus.awaitingPayment:
        return Colors.orange;
      case BookingStatus.held:
        return Colors.red;
      case BookingStatus.cancelled:
        return Colors.grey;
      case BookingStatus.expired:
        return Theme.of(context).colorScheme.outline;
    }
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final _Trend trend;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final trendColor = trend.color ?? colorScheme.primary;
    return Card(
      elevation: 0,
      color: colorScheme.primaryContainer.withOpacity(0.35),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(trend.icon ?? Icons.trending_up,
                    color: trendColor, size: 18),
                const SizedBox(width: 6),
                Text(trend.label, style: TextStyle(color: trendColor)),
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

class _Trend {
  final String label;
  final Color? color;
  final IconData? icon;

  const _Trend({required this.label, this.color, this.icon});
}
