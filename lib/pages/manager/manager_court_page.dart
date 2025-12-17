import 'package:flutter/material.dart';

import '../../models/court.dart';
import '../../services/court_service.dart';
import 'court_images_page.dart';
import 'court_services_page.dart';

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
      backgroundColor: Colors.transparent,
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

  void _openImageManager(Court court) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CourtImagesPage(court: court),
      ),
    );
  }

  void _openServiceManager(Court court) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CourtServicesPage(court: court),
      ),
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

        final theme = Theme.of(context);

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.08),
                      theme.colorScheme.secondary.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.08),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.sports_tennis_outlined,
                        color: theme.colorScheme.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sân & dịch vụ',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Quản lý thông tin sân, hình ảnh và dịch vụ đi kèm.',
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: theme.hintColor),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh_outlined),
                      tooltip: 'Tải lại',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              ...courts.map((court) => _CourtCard(
                    court: court,
                    onEdit: () => _showEditSheet(court),
                    onManageImages: () => _openImageManager(court),
                    onManageServices: () => _openServiceManager(court),
                  )),
            ],
          ),
        );
      },
    );
  }
}

class _CourtCard extends StatelessWidget {
  const _CourtCard({
    required this.court,
    required this.onEdit,
    required this.onManageImages,
    required this.onManageServices,
  });

  final Court court;
  final VoidCallback onEdit;
  final VoidCallback onManageImages;
  final VoidCallback onManageServices;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.sports_tennis_outlined,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              court.name,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          _StatusChip(isActive: court.isActive),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        court.location,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.hintColor),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _InfoPill(
                            icon: Icons.call_outlined,
                            label: 'Liên hệ',
                            value: court.phonePretty,
                          ),
                          _InfoPill(
                            icon: Icons.grid_view_outlined,
                            label: 'Số sân',
                            value: court.courtQuantity.toString(),
                          ),
                        ],
                      ),
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.55),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.notes_outlined,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Mô tả & nội quy',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    court.description?.isNotEmpty == true
                        ? court.description!
                        : 'Chưa có mô tả cho sân này.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: onManageServices,
                    icon: const Icon(Icons.miscellaneous_services_outlined),
                    label: const Text('Quản lý dịch vụ'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onManageImages,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Quản lý hình ảnh'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.6),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isActive ? Colors.green : theme.colorScheme.outline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle_outline : Icons.visibility_off_outlined,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? 'Đang hiển thị' : 'Đang ẩn',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
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

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).colorScheme.primary.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.sports_tennis_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Chỉnh sửa thông tin sân',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _submitting ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      tooltip: 'Đóng',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _LabeledField(
                  label: 'Tên sân',
                  child: TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Ví dụ: Quang Sport',
                      prefixIcon: Icon(Icons.home_work_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập tên sân';
                      }
                      return null;
                    },
                  ),
                ),
                _LabeledField(
                  label: 'Địa chỉ',
                  child: TextFormField(
                    controller: _locationCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Số nhà, đường, quận/huyện...',
                      prefixIcon: Icon(Icons.place_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập địa chỉ';
                      }
                      return null;
                    },
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: _LabeledField(
                        label: 'Số điện thoại',
                        child: TextFormField(
                          controller: _phoneCtrl,
                          decoration: const InputDecoration(
                            hintText: '0xxxxxxxxx / +84xxxxxxxxx',
                            prefixIcon: Icon(Icons.call_outlined),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            final phone = value?.trim() ?? '';
                            if (phone.isEmpty) {
                              return 'Vui lòng nhập số điện thoại';
                            }
                            if (!_phoneReg.hasMatch(phone)) {
                              return 'Số điện thoại phải theo định dạng 0xxxxxxxxx hoặc +84xxxxxxxxx';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _LabeledField(
                        label: 'Số sân',
                        child: TextFormField(
                          initialValue: _quantity.toString(),
                          decoration: const InputDecoration(
                            hintText: 'Nhập số sân',
                            prefixIcon: Icon(Icons.grid_view_outlined),
                          ),
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
                      ),
                    ),
                  ],
                ),
                _LabeledField(
                  label: 'Mô tả / nội quy',
                  child: TextFormField(
                    controller: _descCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Thông tin chi tiết giúp khách hiểu hơn...',
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                    maxLines: 3,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Theme.of(context).colorScheme.surfaceVariant,
                  ),
                  child: SwitchListTile.adaptive(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    value: _isActive,
                    onChanged: (value) => setState(() => _isActive = value),
                    title: const Text('Hiển thị sân cho người dùng đặt lịch'),
                    secondary: Icon(
                      _isActive ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _submitting ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Hủy'),
                      ),
                    ),
                    const SizedBox(width: 12),
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
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
