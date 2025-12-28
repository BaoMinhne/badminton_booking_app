import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/booking.dart';
import '../../services/booking_service.dart';
import '../../services/manager_schedule_service.dart';

class ManagerSchedulePage extends StatefulWidget {
  const ManagerSchedulePage({super.key});

  @override
  State<ManagerSchedulePage> createState() => _ManagerSchedulePageState();
}

class _ManagerSchedulePageState extends State<ManagerSchedulePage> {
  final _service = ManagerScheduleService();
  final _realtimeService = ManagerScheduleRealtimeService();

  late Future<ManagerScheduleData> _future;
  ManagerScheduleData? _latestData;
  bool _tableView = true;
  DateTime _selectedDate = DateTime.now();
  bool _isRealtimeRefreshing = false;
  String _selectedCourt = 'all';
  Set<BookingStatus> _statusFilters = {
    BookingStatus.awaitingPayment,
    BookingStatus.confirmed,
  };

  @override
  void initState() {
    super.initState();
    _future = _loadAndCacheSchedule();
  }

  Future<ManagerScheduleData> _loadAndCacheSchedule() async {
    final normalized = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final data = await _service.fetchSchedule(normalized);
    await _realtimeService.subscribe(
      date: normalized,
      courtIds: data.courtIds,
      onChange: _handleRealtimeChange,
    );
    _latestData = data;
    return data;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('vi'),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _future = _loadAndCacheSchedule();
      });
    }
  }

  Future<void> _openFilterSheet() async {
    final current = Set<BookingStatus>.from(_statusFilters);
    final result = await showModalBottomSheet<Set<BookingStatus>>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final statuses = BookingStatus.values;
        return StatefulBuilder(
          builder: (context, modalSetState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter status',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  const Text('Choose which statuses to show in the schedule.'),
                  const SizedBox(height: 12),
                  ...statuses
                      .where(
                        (status) =>
                            status == BookingStatus.awaitingPayment ||
                            status == BookingStatus.confirmed,
                      )
                      .map((status) {
                    final checked = current.contains(status);
                    return CheckboxListTile(
                      value: checked,
                      dense: true,
                      title: Text(_statusText(status)),
                      activeColor: _statusColor(status),
                      onChanged: (value) {
                        modalSetState(() {
                          if (value == true) {
                            current.add(status);
                          } else {
                            current.remove(status);
                          }
                        });
                      },
                    );
                  }),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          modalSetState(
                            () => current.addAll(BookingStatus.values),
                          );
                        },
                        child: const Text('Select all'),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, current),
                        child: const Text('Apply'),
                      )
                    ],
                  )
                ],
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() => _statusFilters = result);
    }
  }

  void _handleRealtimeChange() {
    if (!mounted || _isRealtimeRefreshing) return;
    _isRealtimeRefreshing = true;
    unawaited(
      _loadAndCacheSchedule().then((freshData) {
        if (!mounted) return;
        setState(() {
          _latestData = freshData;
          _future = Future.value(freshData);
        });
      }).whenComplete(() {
        if (mounted) {
          _isRealtimeRefreshing = false;
        }
      }),
    );
  }

  @override
  void dispose() {
    unawaited(_realtimeService.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ManagerScheduleData>(
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
                  'Unable to load schedule: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () =>
                      setState(() => _future = _loadAndCacheSchedule()),
                  icon: const Icon(Icons.refresh_outlined),
                  label: const Text('Retry'),
                )
              ],
            ),
          );
        }

        final data = snapshot.data;
        if (data == null || !data.hasCourts) {
          return const Center(
            child: Text('You do not have any courts to display the schedule.'),
          );
        }

        _latestData ??= data;

        final availableCourtIds = data.courts.map((c) => c.id).toSet();
        if (_selectedCourt != 'all' && !availableCourtIds.contains(_selectedCourt)) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => setState(() => _selectedCourt = 'all'),
          );
        }

        final filteredItems = data.items
            .where((item) {
              final matchesCourt =
                  _selectedCourt == 'all' || item.courtId == _selectedCourt;
              final matchesStatus = _statusFilters.contains(item.status);
              return matchesCourt && matchesStatus;
            })
            .toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('Table'),
                  selected: _tableView,
                  onSelected: (_) => setState(() => _tableView = true),
                ),
                ChoiceChip(
                  label: const Text('Timeline'),
                  selected: !_tableView,
                  onSelected: (_) => setState(() => _tableView = false),
                ),
                FilledButton.tonalIcon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(DateFormat('dd/MM').format(_selectedDate)),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                DropdownButton<String>(
                  value: _selectedCourt,
                  items: [
                    const DropdownMenuItem(
                      value: 'all',
                    child: Text('All'),
                    ),
                    ...data.courts
                        .map(
                          (court) => DropdownMenuItem(
                            value: court.id,
                            child: Text(court.label),
                          ),
                        )
                        .toList(),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedCourt = value);
                  },
                ),
                FilledButton.icon(
                  onPressed: _openFilterSheet,
                  icon: const Icon(Icons.tune),
                  label: const Text('Filter'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filteredItems.isEmpty
                  ? const Center(child: Text('No schedule for this day.'))
                  : _tableView
                      ? _ScheduleTable(
                          items: filteredItems,
                          formatRange: _formatRange,
                          statusColor: _statusColor,
                          statusText: _statusText,
                        )
                      : _TimelineView(
                          items: filteredItems,
                          formatRange: _formatRange,
                          statusColor: _statusColor,
                          statusText: _statusText,
                          onCancelBooking: _confirmCancelBooking,
                        ),
            ),
          ],
        );
      },
    );
  }

  String _formatRange(DateTime start, DateTime end) {
    final formatter = DateFormat('HH:mm');
    return '${formatter.format(start)} - ${formatter.format(end)}';
  }

  Color _statusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.held:
        return Colors.orange;
      case BookingStatus.awaitingPayment:
        return Colors.blue;
      case BookingStatus.confirmed:
        return Colors.green;
      case BookingStatus.cancelled:
        return Colors.grey;
      case BookingStatus.expired:
        return Colors.red.shade300;
    }
  }

  String _statusText(BookingStatus status) {
    switch (status) {
      case BookingStatus.held:
        return 'Held';
      case BookingStatus.awaitingPayment:
        return 'Awaiting payment';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.expired:
        return 'Expired';
    }
  }

  Future<void> _confirmCancelBooking(ScheduleItem item) async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancel booking'),
          content: Text(
            'Are you sure you want to cancel the booking for ${item.customerName}?\n'
            'Time: ${_formatRange(item.startTime, item.endTime)}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Close'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Cancel booking'),
            ),
          ],
        );
      },
    );

    if (shouldCancel != true) return;

    try {
      await _service.cancelBooking(item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking cancelled successfully.')),
      );
      _applyLocalCancellation(item.id);
      _refreshScheduleSilently();
    } on BookingServiceException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  void _applyLocalCancellation(String bookingId) {
    final cached = _latestData;
    if (cached == null) return;

    final updatedItems = cached.items
        .map(
          (scheduleItem) => scheduleItem.id == bookingId
              ? scheduleItem.copyWith(status: BookingStatus.cancelled)
              : scheduleItem,
        )
        .toList();

    final updatedData = ManagerScheduleData(
      courtIds: cached.courtIds,
      courts: cached.courts,
      items: updatedItems,
    );

    setState(() {
      _latestData = updatedData;
      _future = Future.value(updatedData);
    });
  }

  void _refreshScheduleSilently() {
    _loadAndCacheSchedule().then((freshData) {
      if (!mounted) return;
      setState(() {
        _latestData = freshData;
        _future = Future.value(freshData);
      });
    }).catchError((_) {});
  }
}

class _ScheduleTable extends StatelessWidget {
  const _ScheduleTable({
    required this.items,
    required this.formatRange,
    required this.statusColor,
    required this.statusText,
  });

  final List<ScheduleItem> items;
  final String Function(DateTime start, DateTime end) formatRange;
  final Color Function(BookingStatus status) statusColor;
  final String Function(BookingStatus status) statusText;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: SingleChildScrollView(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Court')),
                    DataColumn(label: Text('Time')),
                    DataColumn(label: Text('Customer')),
                    DataColumn(label: Text('Phone')),
                    DataColumn(label: Text('Status')),
                  ],
                  rows: items
                      .map(
                        (item) => DataRow(
                          cells: [
                            DataCell(Text(item.courtLabel)),
                            DataCell(Text(formatRange(item.startTime, item.endTime))),
                            DataCell(Text(item.customerName)),
                            DataCell(Text(item.customerPhone ?? '-')),
                            DataCell(
                              Chip(
                                label: Text(statusText(item.status)),
                                backgroundColor: statusColor(item.status).withOpacity(0.1),
                                side: BorderSide(
                                  color: statusColor(item.status).withOpacity(0.6),
                                ),
                                labelStyle: TextStyle(color: statusColor(item.status)),
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TimelineView extends StatelessWidget {
  const _TimelineView({
    required this.items,
    required this.formatRange,
    required this.statusColor,
    required this.statusText,
    required this.onCancelBooking,
  });

  final List<ScheduleItem> items;
  final String Function(DateTime start, DateTime end) formatRange;
  final Color Function(BookingStatus status) statusColor;
  final String Function(BookingStatus status) statusText;
  final Future<void> Function(ScheduleItem item) onCancelBooking;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          decoration: BoxDecoration(
            color: statusColor(item.status).withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor(item.status).withOpacity(0.3)),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  CircleAvatar(
                    radius: 6,
                    backgroundColor: statusColor(item.status),
                  ),
                  Container(
                    width: 2,
                    height: 60,
                    color: statusColor(item.status).withOpacity(0.4),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          item.courtLabel,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 8),
                        Chip(
                          label: Text(statusText(item.status)),
                          backgroundColor:
                              statusColor(item.status).withOpacity(0.12),
                          labelStyle: TextStyle(color: statusColor(item.status)),
                          side: BorderSide(
                            color: statusColor(item.status).withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      formatRange(item.startTime, item.endTime),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        item.customerName,
                        if (item.customerPhone != null) item.customerPhone!,
                      ].join(' • '),
                    ),
                    if (item.note != null && item.note!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Note: ${item.note}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                    const SizedBox(height: 8),
                    if (item.status == BookingStatus.awaitingPayment)
                      Wrap(
                        spacing: 8,
                        children: [
                          _ActionChip(
                            icon: Icons.cancel_outlined,
                            label: 'Cancel booking',
                            onPressed: () => onCancelBooking(item),
                          ),
                        ],
                      ),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onPressed,
    );
  }
}
