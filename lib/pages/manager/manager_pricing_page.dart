import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/court.dart';
import '../../models/court_detail.dart';
import '../../services/court_service.dart';

class ManagerPricingPage extends StatefulWidget {
  const ManagerPricingPage({super.key, required this.court});

  final Court court;

  @override
  State<ManagerPricingPage> createState() => _ManagerPricingPageState();
}

class _ManagerPricingPageState extends State<ManagerPricingPage> {
  final _service = CourtService();
  late Future<List<CourtPricing>> _future;
  List<CourtPricing>? _cached;

  @override
  void initState() {
    super.initState();
    _future = _loadPricing();
  }

  Future<List<CourtPricing>> _loadPricing() async {
    final pricing = await _service.listCourtPricing(widget.court.id);
    _cached = pricing;
    return pricing;
  }

  Future<void> _refresh() async {
    final next = _loadPricing();
    setState(() => _future = next);
    await next;
  }

  void _updateCached(CourtPricing updated) {
    final current = _cached;
    if (current == null) return;

    final next = [...current];
    final index = next.indexWhere((item) => item.id == updated.id);
    if (index == -1) return;

    next[index] = updated;
    setState(() {
      _cached = next;
      _future = Future.value(next);
    });
  }

  void _showEditPricing(CourtPricing pricing) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _EditPricingSheet(
        pricing: pricing,
        onSaved: (updated) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã cập nhật giá giờ chơi.')),
          );
          _updateCached(updated);
          _refresh();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Giá giờ chơi'),
            Text(
              widget.court.name,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<CourtPricing>>(
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
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

          final pricing = snapshot.data ?? [];
          _cached = pricing;

          if (pricing.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 40),
                  Center(
                    child: Text('Chưa có bảng giá cho sân này.'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: pricing.length,
              itemBuilder: (context, index) {
                final item = pricing[index];
                return _PricingTile(
                  pricing: item,
                  onEdit: () => _showEditPricing(item),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _PricingTile extends StatelessWidget {
  const _PricingTile({required this.pricing, required this.onEdit});

  final CourtPricing pricing;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );

    final timeRange = _buildTimeRange();
    final priceLabel = pricing.pricePerHour != null
        ? formatter.format(pricing.pricePerHour)
        : (pricing.priceLabel ?? 'Chưa có giá');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        title: Text(timeRange),
        subtitle: Text(
          'Giá / giờ',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            Chip(
              label: Text(priceLabel),
              backgroundColor: cs.primaryContainer.withOpacity(0.35),
            ),
            IconButton(
              tooltip: 'Chỉnh sửa giá',
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
            ),
          ],
        ),
      ),
    );
  }

  String _buildTimeRange() {
    final from = pricing.timeFrom?.trim();
    final to = pricing.timeTo?.trim();

    if ((from == null || from.isEmpty) && (to == null || to.isEmpty)) {
      return 'Khung giờ chưa xác định';
    }

    if (from == null || from.isEmpty) return 'Trước $to';
    if (to == null || to.isEmpty) return 'Sau $from';
    return '$from - $to';
  }
}

class _EditPricingSheet extends StatefulWidget {
  const _EditPricingSheet({required this.pricing, required this.onSaved});

  final CourtPricing pricing;
  final ValueChanged<CourtPricing> onSaved;

  @override
  State<_EditPricingSheet> createState() => _EditPricingSheetState();
}

class _EditPricingSheetState extends State<_EditPricingSheet> {
  final _formKey = GlobalKey<FormState>();
  final _priceCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.pricing.pricePerHour?.toString() ?? '';
    _priceCtrl.text = initial;
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final parsed = int.tryParse(_priceCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''));
    if (parsed == null || parsed <= 0) return;

    setState(() => _submitting = true);
    final service = CourtService();

    try {
      final updated = await service.updateCourtPricing(
        id: widget.pricing.id,
        pricePerHour: parsed,
        timeFrom: widget.pricing.timeFrom,
        timeTo: widget.pricing.timeTo,
      );
      widget.onSaved(updated);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pricing = widget.pricing;

    return SafeArea(
      top: false,
      child: DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.4,
        maxChildSize: 0.8,
        builder: (context, controller) {
          return Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 24,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: cs.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.price_change_outlined, color: cs.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Chỉnh sửa giá giờ chơi',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _timeLabel(pricing),
                              style: TextStyle(color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _submitting ? null : () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Giá / giờ (VND)', style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _priceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Ví dụ: 180000',
                              prefixIcon: const Icon(Icons.attach_money_outlined),
                              filled: true,
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Vui lòng nhập giá';
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
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _submitting ? null : _submit,
                              icon: _submitting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.save_outlined),
                              label: const Text('Lưu giá giờ chơi'),
                            ),
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

  static String _timeLabel(CourtPricing pricing) {
    final from = pricing.timeFrom?.trim();
    final to = pricing.timeTo?.trim();

    if ((from == null || from.isEmpty) && (to == null || to.isEmpty)) {
      return 'Khung giờ chưa xác định';
    }
    if (from == null || from.isEmpty) return 'Trước $to';
    if (to == null || to.isEmpty) return 'Sau $from';
    return '$from - $to';
  }
}
