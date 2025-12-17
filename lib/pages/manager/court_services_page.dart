import 'package:flutter/material.dart';

import '../../models/court.dart';
import '../../models/court_detail.dart';
import '../../services/court_service.dart';

class CourtServicesPage extends StatefulWidget {
  const CourtServicesPage({super.key, required this.court});

  final Court court;

  @override
  State<CourtServicesPage> createState() => _CourtServicesPageState();
}

class _CourtServicesPageState extends State<CourtServicesPage> {
  final _service = CourtService();
  late Future<_ServiceData> _future;
  _ServiceData? _cached;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<_ServiceData> _loadData() async {
    final results = await Future.wait([
      _service.listCourtServices(widget.court.id),
      _service.listServiceCatalog(),
    ]);

    return _ServiceData(
      services: results[0] as List<CourtServiceItem>,
      catalog: results[1] as List<ServiceCatalogItem>,
    );
  }

  Future<void> _refresh() async {
    final future = _loadData();
    setState(() {
      _cached = null;
      _future = future;
    });
    await future;
  }

  void _updateCachedService(CourtServiceItem updated) {
    if (_cached == null) return;

    final updatedServices = List<CourtServiceItem>.from(_cached!.services);
    final index = updatedServices.indexWhere((item) => item.id == updated.id);

    if (index == -1) return;

    updatedServices[index] = updated;

    final next = _ServiceData(
      services: updatedServices,
      catalog: _cached!.catalog,
    );

    setState(() {
      _cached = next;
      _future = Future.value(next);
    });
  }

  void _addCachedService(CourtServiceItem created) {
    if (_cached == null) return;

    final next = _ServiceData(
      services: [..._cached!.services, created],
      catalog: _cached!.catalog,
    );

    setState(() {
      _cached = next;
      _future = Future.value(next);
    });
  }

  void _showAddService(List<CourtServiceItem> services, List<ServiceCatalogItem> catalog) {
    final addedIds = services.map((e) => e.serviceId).toSet();
    final available = catalog.where((item) => !addedIds.contains(item.id)).toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tất cả dịch vụ trong danh mục đã được thêm.')),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddServiceSheet(
        court: widget.court,
        catalog: available,
        onSaved: (created) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã thêm dịch vụ.')),
          );
          _addCachedService(created);
          _refresh();
        },
      ),
    );
  }

  void _showEditService(CourtServiceItem item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _EditServiceSheet(
        item: item,
        onSaved: (updated) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã cập nhật dịch vụ.')),
          );
          _updateCachedService(updated);
          _refresh();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dịch vụ bổ sung'),
      ),
      body: FutureBuilder<_ServiceData>(
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
                  Text(snapshot.error.toString(), textAlign: TextAlign.center),
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

          final data = snapshot.data!;
          _cached = data;
          final services = data.services;
          final catalog = data.catalog;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Dịch vụ đang cung cấp',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: catalog.isEmpty
                          ? null
                          : () => _showAddService(services, catalog),
                      icon: const Icon(Icons.add_outlined),
                      label: const Text('Thêm dịch vụ'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (services.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Theme.of(context).colorScheme.surfaceVariant,
                    ),
                    child: const Text(
                      'Chưa có dịch vụ nào. Hãy thêm từ danh mục có sẵn.',
                    ),
                  )
                else
                  ...services.map(
                    (service) => _ServiceTile(
                      item: service,
                      onEdit: () => _showEditService(service),
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

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.item, required this.onEdit});

  final CourtServiceItem item;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final priceText = item.price != null
        ? '${item.price!.toString()}đ${item.unit != null ? '/${item.unit}' : ''}'
        : (item.priceLabel ?? 'Đang cập nhật');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(priceText),
            if (item.note != null) ...[
              const SizedBox(height: 4),
              Text(
                item.note!,
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ],
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.isActive ? Icons.check_circle_outline : Icons.pause_circle_outline,
                  size: 16,
                  color: item.isActive ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 6),
                Text(item.isActive ? 'Đang bật' : 'Đang tắt'),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          tooltip: 'Chỉnh sửa',
          icon: const Icon(Icons.edit_outlined),
          onPressed: onEdit,
        ),
      ),
    );
  }
}

class _AddServiceSheet extends StatefulWidget {
  const _AddServiceSheet({
    required this.court,
    required this.catalog,
    required this.onSaved,
  });

  final Court court;
  final List<ServiceCatalogItem> catalog;
  final ValueChanged<CourtServiceItem> onSaved;

  @override
  State<_AddServiceSheet> createState() => _AddServiceSheetState();
}

class _AddServiceSheetState extends State<_AddServiceSheet> {
  final _formKey = GlobalKey<FormState>();
  final _priceCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  ServiceCatalogItem? _selected;
  bool _saving = false;

  @override
  void dispose() {
    _priceCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selected == null) return;

    setState(() => _saving = true);
    final service = CourtService();
    final price = int.tryParse(_priceCtrl.text.trim());

    try {
      final created = await service.createCourtService(
        courtId: widget.court.id,
        serviceId: _selected!.id,
        price: price,
        note: _noteCtrl.text,
        unit: _selected!.unit,
        serviceName: _selected!.name,
        isActive: true,
      );
      widget.onSaved(created);
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Thêm dịch vụ mới',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ServiceCatalogItem>(
                decoration: const InputDecoration(
                  labelText: 'Chọn dịch vụ từ danh mục',
                  prefixIcon: Icon(Icons.list_alt_outlined),
                ),
                items: widget.catalog
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(item.unit != null
                            ? '${item.name} (${item.unit})'
                            : item.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selected = value),
                validator: (value) {
                  if (value == null) {
                    return 'Vui lòng chọn dịch vụ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceCtrl,
                decoration: InputDecoration(
                  labelText: 'Giá (đơn vị: ${_selected?.unit ?? 'đ'})',
                  hintText: 'Ví dụ: 50000',
                  prefixIcon: const Icon(Icons.payments_outlined),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập giá';
                  }
                  final parsed = int.tryParse(value.trim());
                  if (parsed == null || parsed < 0) {
                    return 'Giá không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú (không bắt buộc)',
                  prefixIcon: Icon(Icons.note_alt_outlined),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _submit,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Lưu dịch vụ'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditServiceSheet extends StatefulWidget {
  const _EditServiceSheet({required this.item, required this.onSaved});

  final CourtServiceItem item;
  final ValueChanged<CourtServiceItem> onSaved;

  @override
  State<_EditServiceSheet> createState() => _EditServiceSheetState();
}

class _EditServiceSheetState extends State<_EditServiceSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _priceCtrl;
  late final TextEditingController _noteCtrl;
  late bool _isActive;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _priceCtrl = TextEditingController(
      text: widget.item.price != null ? widget.item.price.toString() : '',
    );
    _noteCtrl = TextEditingController(text: widget.item.note ?? '');
    _isActive = widget.item.isActive;
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final service = CourtService();
    final price = int.tryParse(_priceCtrl.text.trim());

    try {
      final updated = await service.updateCourtService(
        id: widget.item.id,
        price: price,
        note: _noteCtrl.text,
        unit: widget.item.unit,
        serviceName: widget.item.name,
        isActive: _isActive,
      );
      widget.onSaved(updated);
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Chỉnh sửa giá dịch vụ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(widget.item.name),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceCtrl,
                decoration: InputDecoration(
                  labelText: 'Giá (đơn vị: ${widget.item.unit ?? 'đ'})',
                  prefixIcon: const Icon(Icons.payments_outlined),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập giá';
                  }
                  final parsed = int.tryParse(value.trim());
                  if (parsed == null || parsed < 0) {
                    return 'Giá không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú (không bắt buộc)',
                  prefixIcon: Icon(Icons.note_alt_outlined),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
                title: const Text('Hiển thị dịch vụ cho người dùng'),
                secondary: Icon(
                  _isActive
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _submit,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Lưu thay đổi'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceData {
  _ServiceData({required this.services, required this.catalog});

  final List<CourtServiceItem> services;
  final List<ServiceCatalogItem> catalog;
}
