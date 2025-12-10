import 'package:flutter/material.dart';

class ManagerCourtPage extends StatelessWidget {
  const ManagerCourtPage({super.key});

  @override
  Widget build(BuildContext context) {
    final courts = [
      _CourtProfile(
        name: 'Sân A1',
        address: '123 Trần Phú, Quận 5',
        phone: '0909 888 777',
        services: const ['Gửi xe', 'Khăn nước', 'Thuê vợt'],
      ),
      _CourtProfile(
        name: 'Sân A2',
        address: '123 Trần Phú, Quận 5',
        phone: '0903 111 222',
        services: const ['Gửi xe', 'Nước suối'],
      ),
    ];

    return ListView(
      children: [
        const Text(
          'Thông tin sân',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...courts.map((court) => _CourtCard(profile: court)).toList(),
        const SizedBox(height: 12),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Dịch vụ đi kèm', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: const [
                    _ServiceChip(label: 'Gửi xe • 5.000đ'),
                    _ServiceChip(label: 'Thuê vợt • 25.000đ'),
                    _ServiceChip(label: 'Nước suối • 8.000đ'),
                  ],
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Thêm dịch vụ'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CourtCard extends StatelessWidget {
  final _CourtProfile profile;

  const _CourtCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 6),
                      Text(profile.address),
                      const SizedBox(height: 4),
                      Text('SĐT: ${profile.phone}'),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Chỉnh sửa',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {},
                )
              ],
            ),
            const SizedBox(height: 12),
            const Text('Mô tả & nội quy'),
            const SizedBox(height: 6),
            Text(
              'Giữ sạch sân, không mang giày đinh. Check-in trước 10 phút. Có nước uống và khăn lạnh tại quầy.',
              style: TextStyle(color: Colors.grey.shade800),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              children: profile.services.map((s) => Chip(label: Text(s))).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Cập nhật hình ảnh'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.rule_folder_outlined),
                  label: const Text('Nội quy chi tiết'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _CourtProfile {
  final String name;
  final String address;
  final String phone;
  final List<String> services;

  _CourtProfile({
    required this.name,
    required this.address,
    required this.phone,
    required this.services,
  });
}

class _ServiceChip extends StatelessWidget {
  final String label;

  const _ServiceChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      avatar: const Icon(Icons.miscellaneous_services, size: 16),
    );
  }
}
