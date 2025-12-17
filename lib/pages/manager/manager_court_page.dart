import 'package:flutter/material.dart';

import '../../models/court.dart';
import '../../services/court_service.dart';
import 'court_images_page.dart';
import 'court_services_page.dart';
import 'manager_pricing_page.dart';

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
    setState(() => _future = future);
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
      MaterialPageRoute(builder: (_) => CourtImagesPage(court: court)),
    );
  }

  void _openServiceManager(Court court) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CourtServicesPage(court: court)),
    );
  }

  void _openPricingManager(Court court) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ManagerPricingPage(court: court)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<List<Court>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: theme.colorScheme.error),
                  const SizedBox(height: 8),
                  Text(snapshot.error.toString(), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh_outlined),
                    label: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          );
        }

        final courts = snapshot.data ?? [];
        if (courts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Bạn chưa có sân nào để quản lý.',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tạo sân trong hệ thống trước, sau đó quay lại đây để cập nhật thông tin, hình ảnh và dịch vụ.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh_outlined),
                    label: const Text('Tải lại'),
                  ),
                ],
              ),
            ),
          );
        }

        // NOTE: giảm padding ngang để card "ăn" thêm chiều ngang
        const pageHPad = 12.0;

        return RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(pageHPad, 16, pageHPad, 10),
                sliver: SliverToBoxAdapter(
                  child: _ManagerHeaderCard(
                    courtCount: courts.length,
                    onRefresh: _refresh,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(pageHPad, 0, pageHPad, 12),
                sliver: SliverToBoxAdapter(
                  child: _OverviewSection(courts: courts),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(pageHPad, 6, pageHPad, 12),
                sliver: SliverList.separated(
                  itemCount: courts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final court = courts[index];
                    return _CourtCard(
                      court: court,
                      onEdit: () => _showEditSheet(court),
                      onManageImages: () => _openImageManager(court),
                      onManagePricing: () => _openPricingManager(court),
                      onManageServices: () => _openServiceManager(court),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ManagerHeaderCard extends StatelessWidget {
  const _ManagerHeaderCard({
    required this.courtCount,
    required this.onRefresh,
  });

  final int courtCount;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            cs.primary.withOpacity(0.10),
            cs.tertiary.withOpacity(0.08),
          ],
        ),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.sports_tennis_outlined, color: cs.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sân & dịch vụ',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Bạn đang quản lý $courtCount sân. Cập nhật mô tả, hình ảnh và dịch vụ để tăng chuyển đổi đặt sân.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              onPressed: onRefresh,
              tooltip: 'Tải lại',
              icon: const Icon(Icons.refresh_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewSection extends StatelessWidget {
  const _OverviewSection({required this.courts});
  final List<Court> courts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final total = courts.length;
    final active = courts.where((e) => e.isActive).length;
    final totalSubCourts =
        courts.fold<int>(0, (sum, c) => sum + c.courtQuantity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tổng quan',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),

        // FIX OVERFLOW:
        // - childAspectRatio giảm để mỗi tile cao hơn
        // - tile bên trong xử lý text mềm + FittedBox cho value
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.0,
          children: [
            _StatTile(
              title: 'Sân đang quản lý',
              value: '$total',
              icon: Icons.home_work_outlined,
            ),
            _StatTile(
              title: 'Đang hiển thị',
              value: '$active',
              icon: Icons.visibility_outlined,
            ),
            _StatTile(
              title: 'Tổng số sân con',
              value: '$totalSubCourts',
              icon: Icons.grid_view_outlined,
            ),
            _StatTile(
              title: 'Việc cần làm',
              value: 'Hình ảnh • Dịch vụ',
              icon: Icons.checklist_outlined,
              isTextValue: true,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Mẹo: thêm ít nhất 5 ảnh và 3 dịch vụ để tăng độ tin cậy khi khách chọn sân.',
          style:
              theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.title,
    required this.value,
    required this.icon,
    this.isTextValue = false,
  });

  final String title;
  final String value;
  final IconData icon;
  final bool isTextValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: cs.primary, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2, // FIX: cho phép 2 dòng
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                    height: 1.1, // FIX: giảm line-height
                  ),
                ),
                const SizedBox(height: 4),
                if (isTextValue)
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                    ),
                  )
                else
                  FittedBox(
                    fit: BoxFit.scaleDown, // FIX: value không bao giờ tràn
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CourtCard extends StatelessWidget {
  const _CourtCard({
    required this.court,
    required this.onEdit,
    required this.onManageImages,
    required this.onManagePricing,
    required this.onManageServices,
  });

  final Court court;
  final VoidCallback onEdit;
  final VoidCallback onManageImages;
  final VoidCallback onManagePricing;
  final VoidCallback onManageServices;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withOpacity(0.45),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.home_work_outlined, color: cs.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          court.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _StatusChip(isActive: court.isActive),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                court.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<int>(
                    tooltip: 'Tác vụ',
                    onSelected: (v) {
                      switch (v) {
                        case 0:
                          onEdit();
                          break;
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 0, child: Text('Chỉnh sửa thông tin')),
                    ],
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.more_horiz),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surface.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
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
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: cs.primary.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.description_outlined, color: cs.primary),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Thông tin chi tiết',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      (court.description?.trim().isNotEmpty ?? false)
                          ? court.description!
                          : 'Chưa cập nhật mô tả cho sân này.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: onManagePricing,
                icon: const Icon(Icons.price_change_outlined),
                label: const Text('Giá giờ chơi'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: onManageServices,
                icon: const Icon(Icons.miscellaneous_services_outlined),
                label: const Text('Dịch vụ'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: onManageImages,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Hình ảnh'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Divider(color: cs.outlineVariant.withOpacity(0.8)),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: cs.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: cs.onSurface,
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
    final cs = theme.colorScheme;

    final color = isActive ? Colors.green : cs.outline;
    final bg = color.withOpacity(0.12);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive
                ? Icons.check_circle_outline
                : Icons.visibility_off_outlined,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? 'Đang hiển thị' : 'Đang ẩn',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w900,
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
  late final TextEditingController _priceCtrl;

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
    _priceCtrl = TextEditingController(
      text: widget.court.pricePerHour?.toString() ?? '',
    );
    _quantity = widget.court.courtQuantity;
    _isActive = widget.court.isActive;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _phoneCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    final service = CourtService();

    final price = int.tryParse(
      _priceCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    final normalizedPrice = price ?? widget.court.pricePerHour;

    try {
      final updated = await service.updateCourt(
        courtId: widget.court.id,
        name: _nameCtrl.text,
        location: _locationCtrl.text,
        phone: _phoneCtrl.text,
        courtQuantity: _quantity,
        pricePerHour: normalizedPrice,
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

  InputDecoration _decoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SafeArea(
      top: false,
      child: DraggableScrollableSheet(
        initialChildSize: 0.78,
        minChildSize: 0.55,
        maxChildSize: 0.95,
        builder: (context, scrollCtrl) {
          return Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(26)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 24,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 10, 10),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: cs.primary.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.edit_outlined, color: cs.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Chỉnh sửa thông tin sân',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed:
                            _submitting ? null : () => Navigator.pop(context),
                        tooltip: 'Đóng',
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _LabeledField(
                            label: 'Tên sân',
                            child: TextFormField(
                              controller: _nameCtrl,
                              textInputAction: TextInputAction.next,
                              decoration: _decoration(
                                hint: 'Ví dụ: Quang Sport',
                                icon: Icons.home_work_outlined,
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
                              textInputAction: TextInputAction.next,
                              decoration: _decoration(
                                hint: 'Số nhà, đường, quận/huyện...',
                                icon: Icons.place_outlined,
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
                                    textInputAction: TextInputAction.next,
                                    decoration: _decoration(
                                      hint: '0xxxxxxxxx / +84xxxxxxxxx',
                                      icon: Icons.call_outlined,
                                    ),
                                    keyboardType: TextInputType.phone,
                                    validator: (value) {
                                      final phone = value?.trim() ?? '';
                                      if (phone.isEmpty)
                                        return 'Vui lòng nhập số điện thoại';
                                      if (!_phoneReg.hasMatch(phone)) {
                                        return 'Sai định dạng 0xxxxxxxxx hoặc +84xxxxxxxxx';
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
                                    decoration: _decoration(
                                      hint: 'Nhập số sân',
                                      icon: Icons.grid_view_outlined,
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      final parsed = int.tryParse(value);
                                      if (parsed != null && parsed > 0)
                                        _quantity = parsed;
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
                            label: 'Giá sân/giờ (VND)',
                            child: TextFormField(
                              controller: _priceCtrl,
                              textInputAction: TextInputAction.next,
                              decoration: _decoration(
                                hint: 'Ví dụ: 180000',
                                icon: Icons.price_change_outlined,
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return null;
                                }
                                final parsed = int.tryParse(
                                  value.replaceAll(RegExp(r'[^0-9]'), ''),
                                );
                                if (parsed == null || parsed <= 0) {
                                  return 'Giá phải là số dương';
                                }
                                return null;
                              },
                            ),
                          ),
                          _LabeledField(
                            label: 'Mô tả / nội quy',
                            child: TextFormField(
                              controller: _descCtrl,
                              decoration: _decoration(
                                hint:
                                    'Thông tin chi tiết giúp khách hiểu hơn...',
                                icon: Icons.notes_outlined,
                              ),
                              maxLines: 4,
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color:
                                  cs.surfaceContainerHighest.withOpacity(0.55),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: cs.outlineVariant.withOpacity(0.6)),
                            ),
                            child: SwitchListTile.adaptive(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              value: _isActive,
                              onChanged: _submitting
                                  ? null
                                  : (v) => setState(() => _isActive = v),
                              title: const Text(
                                  'Hiển thị sân cho người dùng đặt lịch'),
                              subtitle: Text(
                                _isActive
                                    ? 'Sân sẽ xuất hiện trên danh sách đặt lịch.'
                                    : 'Sân bị ẩn khỏi danh sách đặt lịch.',
                              ),
                              secondary: Icon(
                                _isActive
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _submitting
                                      ? null
                                      : () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
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
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        )
                                      : const Icon(Icons.save_outlined),
                                  label: const Text('Lưu thay đổi'),
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
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
              ],
            ),
          );
        },
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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface.withOpacity(0.85),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
