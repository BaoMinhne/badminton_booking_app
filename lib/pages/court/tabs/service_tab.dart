import 'package:badminton_booking_app/utils/currency.dart';
import 'package:flutter/material.dart';

class ServicePrice {
  final String name; // Tên dịch vụ: "Thuê sân đơn"
  final String unit; // Đơn vị: "giờ", "buổi", "set", ...
  final int? price; // Giá: 120000
  final bool isPeak; // Có phải giờ cao điểm?
  final String? note; // Ghi chú (tuỳ chọn)

  const ServicePrice({
    required this.name,
    required this.unit,
    required this.price,
    this.isPeak = false,
    this.note,
  });
}

class PricingTableMini extends StatelessWidget {
  final String title;
  final List<ServicePrice> items;
  final List<String> units;

  const PricingTableMini({
    super.key,
    this.title = "Bảng giá dịch vụ",
    required this.items,
    this.units = const [],
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // (tuỳ chọn) Sắp xếp: giờ thường trước, cao điểm sau
    final sorted = [...items]..sort((a, b) {
        if (a.isPeak == b.isPeak) return a.name.compareTo(b.name);
        return a.isPeak ? 1 : -1;
      });

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),

        if (units.isNotEmpty) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: units
                  .map(
                    (unit) => Chip(
                      label: Text(unit),
                      backgroundColor: cs.primary.withOpacity(0.12),
                      labelStyle: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Khung bảng
        Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outline),
          ),
          child: Column(
            children: [
              // Header hàng (Tên dịch vụ / Giá)
              _headerRow(context),

              // Dòng dữ liệu
              if (sorted.isEmpty)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 18, color: cs.onSurface.withOpacity(0.6)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sân chưa cập nhật bảng giá.',
                          style: TextStyle(
                            color: cs.onSurface.withOpacity(0.75),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                for (final sp in sorted) _priceRow(context, sp),
            ],
          ),
        ),

        // Gợi ý chú thích
        const SizedBox(height: 12),
        _hint(
          context,
          'Giờ cao điểm ví dụ: 17:00–21:00 các ngày trong tuần.\n'
          'Giá đã bao gồm VAT (nếu có). Vui lòng đặt trước để giữ sân.',
        ),
      ],
    );
  }

  static Widget _headerRow(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(0.6),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: const [
          Expanded(
            child:
                Text("Dịch vụ", style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          SizedBox(width: 12),
          Text("Giá", style: TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  static Widget _priceRow(BuildContext context, ServicePrice sp) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: cs.outline.withOpacity(0.15)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cột trái: tên + badge + ghi chú
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tên + badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        sp.name,
                        style: const TextStyle(fontSize: 15, height: 1.2),
                      ),
                    ),
                    if (sp.isPeak) _badge(cs, "Cao điểm"),
                  ],
                ),
                // Ghi chú (nếu có)
                if (sp.note != null && sp.note!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    sp.note!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.65),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Cột phải: giá + đơn vị
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                sp.price != null ? formatVND(sp.price!) : 'Liên hệ',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: cs.primary,
                ),
              ),
              Text(
                "/ ${sp.unit}",
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _badge(ColorScheme cs, String text) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.primary.withOpacity(0.25)),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, color: cs.primary)),
    );
  }

  static Widget _hint(BuildContext context, String text) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.primary.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 16, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(height: 1.35))),
        ],
      ),
    );
  }
}
