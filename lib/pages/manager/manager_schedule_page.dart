import 'package:flutter/material.dart';

class ManagerSchedulePage extends StatefulWidget {
  const ManagerSchedulePage({super.key});

  @override
  State<ManagerSchedulePage> createState() => _ManagerSchedulePageState();
}

class _ManagerSchedulePageState extends State<ManagerSchedulePage> {
  bool _tableView = true;
  DateTime _selectedDate = DateTime.now();
  String _selectedCourt = 'Tất cả';

  final List<String> _courts = const ['Tất cả', 'Sân 1', 'Sân 2', 'Sân 3'];
  final List<_ScheduleItem> _items = const [
    _ScheduleItem(
      court: 'Sân 1',
      start: '06:00',
      end: '07:30',
      customer: 'Nguyễn Minh',
      phone: '0901 234 567',
      status: 'Confirmed',
      color: Colors.green,
    ),
    _ScheduleItem(
      court: 'Sân 2',
      start: '08:00',
      end: '10:00',
      customer: 'Trần Thảo',
      phone: '0933 888 999',
      status: 'Offline',
      color: Colors.orange,
    ),
    _ScheduleItem(
      court: 'Sân 3',
      start: '10:00',
      end: '12:00',
      customer: 'CLB Đồng Đội',
      phone: '0912 456 789',
      status: 'Blocked',
      color: Colors.red,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filteredItems = _selectedCourt == 'Tất cả'
        ? _items
        : _items.where((item) => item.court == _selectedCourt).toList();

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
            ElevatedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(_formattedDate(_selectedDate)),
            ),
            DropdownButton<String>(
              value: _selectedCourt,
              items: _courts
                  .map((court) => DropdownMenuItem(
                        value: court,
                        child: Text(court),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedCourt = value);
              },
            ),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.search),
              label: const Text('Lọc'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _tableView
              ? _ScheduleTable(items: filteredItems)
              : _TimelineView(items: filteredItems),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  String _formattedDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }
}

class _ScheduleTable extends StatelessWidget {
  final List<_ScheduleItem> items;

  const _ScheduleTable({required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
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
                  (item) => DataRow(cells: [
                    DataCell(Text(item.court)),
                    DataCell(Text('${item.start} - ${item.end}')),
                    DataCell(Text(item.customer)),
                    DataCell(Text(item.phone)),
                    DataCell(Chip(
                      label: Text(item.status),
                      backgroundColor: item.color.withOpacity(0.1),
                      side: BorderSide(color: item.color.withOpacity(0.6)),
                      labelStyle: TextStyle(color: item.color),
                    )),
                  ]),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _TimelineView extends StatelessWidget {
  final List<_ScheduleItem> items;

  const _TimelineView({required this.items});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          decoration: BoxDecoration(
            color: item.color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: item.color.withOpacity(0.3)),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  CircleAvatar(radius: 6, backgroundColor: item.color),
                  Container(
                    width: 2,
                    height: 60,
                    color: item.color.withOpacity(0.4),
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
                        Text(item.court, style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(width: 8),
                        Chip(
                          label: Text(item.status),
                          backgroundColor: item.color.withOpacity(0.12),
                          labelStyle: TextStyle(color: item.color),
                          side: BorderSide(color: item.color.withOpacity(0.6)),
                        ),
                      ],
                    ),
                    Text('${item.start} - ${item.end}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('${item.customer} • ${item.phone}'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: const [
                        _ActionChip(icon: Icons.swap_horiz, label: 'Đổi giờ/sân'),
                        _ActionChip(icon: Icons.cancel_outlined, label: 'Hủy booking'),
                        _ActionChip(icon: Icons.block, label: 'Block slot'),
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
  final IconData icon;
  final String label;

  const _ActionChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: () {},
    );
  }
}

class _ScheduleItem {
  final String court;
  final String start;
  final String end;
  final String customer;
  final String phone;
  final String status;
  final Color color;

  const _ScheduleItem({
    required this.court,
    required this.start,
    required this.end,
    required this.customer,
    required this.phone,
    required this.status,
    required this.color,
  });
}
