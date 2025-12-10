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
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Bảng giá sân',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 24),
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
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Loại sân')),
                          DataColumn(label: Text('Ngày áp dụng')),
                          DataColumn(label: Text('Khung giờ')),
                          DataColumn(label: Text('Loại giá')),
                          DataColumn(label: Text('Giá')), 
                          DataColumn(label: Text('Thao tác')),
                        ],
                        rows: pricing.map((row) {
                          return DataRow(
                            cells: [
                              DataCell(Text(row.label, style: const TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(Text(row.day)),
                              DataCell(Text(row.time)),
                              DataCell(
                                Chip(
                                  label: Text(row.tag),
                                  avatar: const Icon(Icons.bolt, size: 16),
                                ),
                              ),
                              DataCell(
                                Chip(
                                  label: Text(row.price),
                                  backgroundColor: Colors.green.shade50,
                                ),
                              ),
                              DataCell(
                                Wrap(
                                  spacing: 8,
                                  children: [
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
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
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
