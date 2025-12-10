import 'package:flutter/material.dart';

class ManagerOperatingHoursPage extends StatelessWidget {
  const ManagerOperatingHoursPage({super.key});

  @override
  Widget build(BuildContext context) {
    final weekly = [
      _OperatingHour(day: 'Thứ 2', open: '06:00', close: '22:00'),
      _OperatingHour(day: 'Thứ 3', open: '06:00', close: '22:00'),
      _OperatingHour(day: 'Thứ 4', open: '06:00', close: '22:00'),
      _OperatingHour(day: 'Thứ 5', open: '06:00', close: '22:00'),
      _OperatingHour(day: 'Thứ 6', open: '06:00', close: '22:00'),
      _OperatingHour(day: 'Thứ 7', open: '06:00', close: '23:00'),
      _OperatingHour(day: 'Chủ nhật', open: '07:00', close: '23:00'),
    ];

    final closures = [
      _ClosureRange(label: 'Nghỉ lễ 2/9', range: '01/09 - 02/09'),
      _ClosureRange(label: 'Bảo trì điện', range: '15/10 (cả ngày)'),
    ];

    final specialSlots = [
      _SpecialSlot(label: 'Giải phong trào CLB', time: 'Sân 3 • 10:00 - 12:00 • 12/10'),
      _SpecialSlot(label: 'Thuê dài hạn', time: 'Sân 1 • Thứ 3 & 5 • 18:00 - 20:00'),
    ];

    return ListView(
      children: [
        const Text('Giờ mở cửa 7 ngày', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: weekly
                .map(
                  (item) => ListTile(
                    title: Text(item.day),
                    subtitle: Text('${item.open} - ${item.close}'),
                    trailing: IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 12),
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
                      child: Text('Ngày nghỉ / đóng cửa', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Thêm ngày nghỉ'),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                ...closures
                    .map(
                      (closure) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.event_busy_outlined),
                        title: Text(closure.label),
                        subtitle: Text(closure.range),
                        trailing: IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ),
                    )
                    .toList(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
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
                      child: Text('Khung giờ đặc biệt', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add_alert_outlined),
                      label: const Text('Thêm khung giờ'),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                ...specialSlots
                    .map(
                      (slot) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.block_outlined),
                        title: Text(slot.label),
                        subtitle: Text(slot.time),
                        trailing: IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.edit_calendar_outlined),
                        ),
                      ),
                    )
                    .toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OperatingHour {
  final String day;
  final String open;
  final String close;

  _OperatingHour({required this.day, required this.open, required this.close});
}

class _ClosureRange {
  final String label;
  final String range;

  _ClosureRange({required this.label, required this.range});
}

class _SpecialSlot {
  final String label;
  final String time;

  _SpecialSlot({required this.label, required this.time});
}
