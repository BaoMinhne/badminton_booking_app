import 'package:flutter/material.dart';

class ManagerPricingPage extends StatelessWidget {
  const ManagerPricingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final pricing = [
      _PriceRow(label: 'Sân tiêu chuẩn', day: 'Thứ 2 - Thứ 6', time: '06:00 - 17:00', price: '120.000đ', tag: 'Thấp điểm'),
      _PriceRow(label: 'Sân tiêu chuẩn', day: 'Thứ 2 - Thứ 6', time: '17:00 - 22:00', price: '180.000đ', tag: 'Cao điểm'),
      _PriceRow(label: 'Sân VIP', day: 'Thứ 7, CN', time: '06:00 - 22:00', price: '220.000đ', tag: 'Cao điểm'),
      _PriceRow(label: 'Giải đấu 12/10', day: '12/10', time: 'Cả ngày', price: 'Block', tag: 'Sự kiện'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final actionButtons = Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: [
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.upload_file_outlined),
              label: const Text('Import/Export JSON'),
            ),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text('Thêm dòng giá'),
            ),
          ],
        );

        final header = SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Row(
              children: [
                const Text(
                  'Bảng giá sân',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                actionButtons,
              ],
            ),
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,
            const SizedBox(height: 12),
            Expanded(
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final row = pricing[index];
                    return ListTile(
                      leading: const Icon(Icons.price_change_outlined),
                      title: Text(row.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${row.day} • ${row.time}'),
                      trailing: Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Chip(
                            label: Text(row.tag),
                            avatar: const Icon(Icons.bolt, size: 16),
                          ),
                          Chip(
                            label: Text(row.price),
                            backgroundColor: Colors.green.shade50,
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.copy_outlined),
                            tooltip: 'Nhân bản',
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: 'Chỉnh sửa',
                          ),
                        ],
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const Divider(),
                  itemCount: pricing.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PriceRow {
  final String label;
  final String day;
  final String time;
  final String price;
  final String tag;

  _PriceRow({
    required this.label,
    required this.day,
    required this.time,
    required this.price,
    required this.tag,
  });
}
