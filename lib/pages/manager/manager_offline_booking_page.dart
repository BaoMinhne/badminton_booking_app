import 'package:flutter/material.dart';

class ManagerOfflineBookingPage extends StatefulWidget {
  const ManagerOfflineBookingPage({super.key});

  @override
  State<ManagerOfflineBookingPage> createState() => _ManagerOfflineBookingPageState();
}

class _ManagerOfflineBookingPageState extends State<ManagerOfflineBookingPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _start = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 9, minute: 0);
  String _court = 'Sân 1';
  String _paymentMethod = 'Tiền mặt';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tạo booking offline',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    _buildTextField(
                      controller: _nameController,
                      label: 'Tên khách',
                      validator: (v) => (v == null || v.isEmpty) ? 'Nhập tên khách' : null,
                    ),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Số điện thoại',
                      keyboardType: TextInputType.phone,
                      validator: (v) => (v == null || v.isEmpty) ? 'Nhập SĐT' : null,
                    ),
                    _buildPickerField(
                      label: 'Ngày',
                      value: '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      onTap: _pickDate,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildPickerField(
                          label: 'Giờ bắt đầu',
                          value: _start.format(context),
                          onTap: () => _pickTime(isStart: true),
                        ),
                        const SizedBox(width: 12),
                        _buildPickerField(
                          label: 'Giờ kết thúc',
                          value: _end.format(context),
                          onTap: () => _pickTime(isStart: false),
                        ),
                      ],
                    ),
                    DropdownButtonFormField<String>(
                      value: _court,
                      decoration: const InputDecoration(labelText: 'Chọn sân'),
                      items: const [
                        DropdownMenuItem(value: 'Sân 1', child: Text('Sân 1')),
                        DropdownMenuItem(value: 'Sân 2', child: Text('Sân 2')),
                        DropdownMenuItem(value: 'Sân 3', child: Text('Sân 3')),
                      ],
                      onChanged: (value) => setState(() => _court = value ?? 'Sân 1'),
                    ),
                    DropdownButtonFormField<String>(
                      value: _paymentMethod,
                      decoration: const InputDecoration(labelText: 'Hình thức thanh toán'),
                      items: const [
                        DropdownMenuItem(value: 'Tiền mặt', child: Text('Tiền mặt')),
                        DropdownMenuItem(value: 'Chuyển khoản', child: Text('Chuyển khoản')),
                      ],
                      onChanged: (value) => setState(() => _paymentMethod = value ?? 'Tiền mặt'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noteController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Ghi chú / nhu cầu đặc biệt'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Tạo booking'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () => _formKey.currentState?.reset(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Làm mới'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                const Text(
                  'Lịch sử gần đây',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...const [
                  _OfflineHistoryTile(name: 'Đặng Khoa', time: 'Hôm qua • Sân 2 • 18:00 - 20:00', payment: 'Tiền mặt'),
                  _OfflineHistoryTile(name: 'CLB Z', time: 'Tuần trước • Sân 1 • 06:00 - 08:00', payment: 'Chuyển khoản'),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return SizedBox(
      width: 260,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label),
        validator: validator,
      ),
    );
  }

  Widget _buildPickerField({required String label, required String value, required VoidCallback onTap}) {
    return SizedBox(
      width: 200,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: InputDecorator(
          decoration: InputDecoration(labelText: label),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(value),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _start : _end,
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = picked;
      } else {
        _end = picked;
      }
    });
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã tạo booking offline cho $_court (${_start.format(context)} - ${_end.format(context)})'),
      ),
    );
  }
}

class _OfflineHistoryTile extends StatelessWidget {
  final String name;
  final String time;
  final String payment;

  const _OfflineHistoryTile({required this.name, required this.time, required this.payment});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(child: Icon(Icons.person)),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(time),
      trailing: Chip(
        label: Text(payment),
        avatar: const Icon(Icons.payments_outlined),
      ),
    );
  }
}
