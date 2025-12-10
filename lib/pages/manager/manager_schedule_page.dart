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

  late Future<ManagerScheduleData> _future;
  bool _tableView = true;
  DateTime _selectedDate = DateTime.now();
  String _selectedCourt = 'all';
  Set<BookingStatus> _statusFilters = {
    BookingStatus.held,
    BookingStatus.awaitingPayment,
    BookingStatus.confirmed,
  };

  @override
  void initState() {
    super.initState();
    _future = _loadSchedule();
  }

  Future<ManagerScheduleData> _loadSchedule() {
    final normalized = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    return _service.fetchSchedule(normalized);
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
        _future = _loadSchedule();
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
                    'Lọc trạng thái',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  const Text('Chọn những trạng thái muốn hiển thị trong lịch.'),
                  const SizedBox(height: 12),
                  ...statuses.map((status) {
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
                        child: const Text('Chọn tất cả'),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Huỷ'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, current),
                        child: const Text('Áp dụng'),
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
                  'Không thể tải lịch: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => setState(() => _future = _loadSchedule()),
                  icon: const Icon(Icons.refresh_outlined),
                  label: const Text('Thử lại'),
                )
              ],
            ),
          );
        }

        final data = snapshot.data;
        if (data == null || !data.hasCourts) {
          return const Center(
            child: Text('Bạn chưa có sân nào để hiển thị lịch.'),
          );
        }

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
                  label: const Text('Bảng'),
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
                      child: Text('Tất cả'),
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
                  label: const Text('Lọc'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filteredItems.isEmpty
                  ? const Center(child: Text('Không có lịch trong ngày.'))
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
                          onAction: _showComingSoon,
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
        return 'Giữ chỗ';
      case BookingStatus.awaitingPayment:
        return 'Chờ thanh toán';
      case BookingStatus.confirmed:
        return 'Đã thanh toán';
      case BookingStatus.cancelled:
        return 'Đã huỷ';
      case BookingStatus.expired:
        return 'Hết hạn';
    }
  }

  void _showComingSoon(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$action đang được phát triển.')),
    );
  }

  Future<void> _confirmCancelBooking(ScheduleItem item) async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Huỷ booking'),
          content: Text(
            'Bạn có chắc muốn huỷ booking của ${item.customerName}?\n'
            'Thời gian: ${_formatRange(item.startTime, item.endTime)}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Đóng'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Huỷ booking'),
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
        const SnackBar(content: Text('Đã huỷ booking thành công.')),
      );
      setState(() => _future = _loadSchedule());
    } on BookingServiceException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
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
                    DataColumn(label: Text('Sân')),
                    DataColumn(label: Text('Giờ')),
                    DataColumn(label: Text('Khách')),
                    DataColumn(label: Text('SĐT')),
                    DataColumn(label: Text('Trạng thái')),
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
    required this.onAction,
    required this.onCancelBooking,
  });

  final List<ScheduleItem> items;
  final String Function(DateTime start, DateTime end) formatRange;
  final Color Function(BookingStatus status) statusColor;
  final String Function(BookingStatus status) statusText;
  final void Function(String action) onAction;
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
                        'Ghi chú: ${item.note}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _ActionChip(
                          icon: Icons.swap_horiz,
                          label: 'Đổi giờ/sân',
                          onPressed: () => onAction('Đổi giờ/sân'),
                        ),
                        _ActionChip(
                          icon: Icons.cancel_outlined,
                          label: 'Hủy booking',
                          onPressed: () => onCancelBooking(item),
                        ),
                        _ActionChip(
                          icon: Icons.phone_forwarded_outlined,
                          label: 'Liên hệ',
                          onPressed: () => onAction('Liên hệ khách'),
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
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onPressed,
    );
  }
}
