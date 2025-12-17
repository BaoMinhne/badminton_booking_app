import 'package:flutter/material.dart';

import '../../models/court.dart';
import '../../services/court_service.dart';

class ManagerCourtPage extends StatefulWidget {
  const ManagerCourtPage({super.key});

  @override
  State<ManagerCourtPage> createState() => _ManagerCourtPageState();
}

class _ManagerCourtPageState extends State<ManagerCourtPage> {
  final _courtService = CourtService();
  late Future<List<Court>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadCourts();
  }

  Future<List<Court>> _loadCourts() {
    return _courtService.listOwnerCourts(perPage: 100);
  }

  Future<void> _refresh() async {
    final future = _loadCourts();
    setState(() {
      _future = future;
    });
    await future;
  }

  void _showEditSheet(Court court) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _EditCourtSheet(
          court: court,
          onSaved: (updated) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã cập nhật thông tin sân.')),
            );
            _refresh();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Court>>(
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
                  label: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        final courts = snapshot.data ?? [];
        if (courts.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Bạn chưa có sân nào để chỉnh sửa.'),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh_outlined),
                  label: const Text('Tải lại'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              const Text(
                'Thông tin sân',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...courts.map((court) => _CourtCard(
                    court: court,
                    onEdit: () => _showEditSheet(court),
                  )),
            ],
          ),
        );
      },
    );
  }
}

class _CourtCard extends StatelessWidget {
  const _CourtCard({required this.court, required this.onEdit});

  final Court court;
  final VoidCallback onEdit;

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
                      Row(
                        children: [
                          Text(
                            court.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            avatar: Icon(
                              court.isActive
                                  ? Icons.check_circle_outline
                                  : Icons.visibility_off_outlined,
                              size: 16,
                              color: court.isActive ? Colors.green : Colors.grey,
                            ),
                            label: Text(
                              court.isActive ? 'Đang hiển thị' : 'Đang ẩn',
                              style: TextStyle(
                                color:
                                    court.isActive ? Colors.green : Colors.grey,
                              ),
                            ),
                            side: BorderSide(
                              color:
                                  court.isActive ? Colors.green : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(court.location),
                      const SizedBox(height: 4),
                      Text('SĐT: ${court.phonePretty}'),
                      const SizedBox(height: 4),
                      Text('Số sân: ${court.courtQuantity}'),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Chỉnh sửa',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: onEdit,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Mô tả & nội quy'),
            const SizedBox(height: 6),
            Text(
              court.description?.isNotEmpty == true
                  ? court.description!
                  : 'Chưa có mô tả cho sân này.',
              style: TextStyle(color: Colors.grey.shade800),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditCourtSheet extends StatefulWidget {
  const _EditCourtSheet({required this.court, required this.onSaved});

  final Court court;
  final ValueChanged<Court> onSaved;

  @override
  State<_EditCourtSheet> createState() => _EditCourtSheetState();
}

class _EditCourtSheetState extends State<_EditCourtSheet> {
  final _formKey = GlobalKey<FormState>();
  final _phoneReg = RegExp(r'^(?:0|\+84)\d{9}$');
  late final TextEditingController _nameCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _descCtrl;
  late int _quantity;
  late bool _isActive;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.court.name);
    _locationCtrl = TextEditingController(text: widget.court.location);
    _phoneCtrl = TextEditingController(text: widget.court.phoneLocal);
    _descCtrl = TextEditingController(text: widget.court.description ?? '');
    _quantity = widget.court.courtQuantity;
    _isActive = widget.court.isActive;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _phoneCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    final service = CourtService();

    try {
      final updated = await service.updateCourt(
        courtId: widget.court.id,
        name: _nameCtrl.text,
        location: _locationCtrl.text,
        phone: _phoneCtrl.text,
        courtQuantity: _quantity,
        isActive: _isActive,
        description: _descCtrl.text,
      );
      widget.onSaved(updated);
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Chỉnh sửa thông tin sân',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Tên sân'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên sân';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _locationCtrl,
                decoration: const InputDecoration(labelText: 'Địa chỉ'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập địa chỉ';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(labelText: 'Số điện thoại'),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  final phone = value?.trim() ?? '';
                  if (phone.isEmpty) return 'Vui lòng nhập số điện thoại';
                  if (!_phoneReg.hasMatch(phone)) {
                    return 'Số điện thoại phải theo định dạng 0xxxxxxxxx hoặc +84xxxxxxxxx';
                  }
                  return null;
                },
              ),
              TextFormField(
                initialValue: _quantity.toString(),
                decoration: const InputDecoration(labelText: 'Số sân hiện có'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final parsed = int.tryParse(value);
                  if (parsed != null && parsed > 0) {
                    _quantity = parsed;
                  }
                },
                validator: (value) {
                  final parsed = int.tryParse(value ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Số sân phải lớn hơn 0';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Mô tả / nội quy'),
                maxLines: 3,
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
                title: const Text('Hiển thị sân cho người dùng đặt lịch'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _submitting ? null : _submit,
                      icon: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: const Text('Lưu thay đổi'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _submitting ? null : () => Navigator.pop(context),
                    child: const Text('Hủy'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
