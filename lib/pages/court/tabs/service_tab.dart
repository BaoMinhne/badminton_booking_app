import 'package:badminton_booking_app/models/court_detail.dart';
import 'package:badminton_booking_app/utils/currency.dart';
import 'package:flutter/material.dart';

class ServicePrice {
  final String name; // Tên dịch vụ: "Thuê sân đơn"
  final String? unit; // Đơn vị: "giờ", "buổi", "set", ...
  final int? price; // Giá: 120000
  final String? priceLabel; // Giá dạng chữ nếu không parse được
  final bool isPeak; // Có phải giờ cao điểm?
  final String? note; // Ghi chú (tuỳ chọn)

  const ServicePrice({
    required this.name,
    this.unit,
    this.price,
    this.priceLabel,
    this.isPeak = false,
    this.note,
  });

  factory ServicePrice.fromCourtPricing(CourtPricing pricing) {
    final from = pricing.timeFrom?.trim();
    final to = pricing.timeTo?.trim();
    String name;

    if ((from?.isNotEmpty ?? false) && (to?.isNotEmpty ?? false)) {
      name = '$from - $to';
    } else if (from?.isNotEmpty ?? false) {
      name = 'Từ $from';
    } else if (to?.isNotEmpty ?? false) {
      name = 'Đến $to';
    } else {
      name = 'Giá theo giờ';
    }

    return ServicePrice(
      name: name,
      unit: 'giờ',
      price: pricing.pricePerHour,
      priceLabel: pricing.priceLabel,
    );
  }

  factory ServicePrice.fromCourtService(CourtServiceItem service) {
    return ServicePrice(
      name: service.name,
      unit: service.unit,
      price: service.price,
      priceLabel: service.priceLabel,
      note: service.note,
    );
  }

  bool get hasPrice => price != null || (priceLabel?.trim().isNotEmpty ?? false);
}

class PricingTableMini extends StatelessWidget {
  final String title;
  final List<ServicePrice> items;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final String emptyLabel;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final String? hintText;

  const PricingTableMini({
    super.key,
    this.title = "Bảng giá dịch vụ",
    required this.items,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    this.emptyLabel = 'Chưa có dữ liệu giá cho sân này.',
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.hintText =
        'Giờ cao điểm ví dụ: 17:00–21:00 các ngày trong tuần.\nGiá đã bao gồm VAT (nếu có). Vui lòng đặt trước để giữ sân.',
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (errorMessage != null) {
      return _messageView(
        context,
        icon: Icons.error_outline,
        color: Colors.redAccent,
        message: 'Không thể tải bảng giá.\n$errorMessage',
        action: onRetry,
        actionLabel: 'Thử lại',
      );
    }

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // (tuỳ chọn) Sắp xếp: giờ thường trước, cao điểm sau
    final sorted = [...items]..sort((a, b) {
        if (a.isPeak == b.isPeak) return a.name.compareTo(b.name);
        return a.isPeak ? 1 : -1;
      });

    if (sorted.isEmpty) {
      return _messageView(
        context,
        icon: Icons.info_outline,
        color: cs.primary,
        message: emptyLabel,
        action: onRetry,
        actionLabel: 'Tải lại',
      );
    }

    final effectivePadding = padding ?? const EdgeInsets.all(16);
    final effectivePhysics = physics ??
        (shrinkWrap ? const NeverScrollableScrollPhysics() : null);

    return ListView(
      padding: effectivePadding,
      shrinkWrap: shrinkWrap,
      physics: effectivePhysics,
      children: [
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),

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
              for (final sp in sorted) _priceRow(context, sp),
            ],
          ),
        ),

        // Gợi ý chú thích
        if (hintText != null && hintText!.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          _hint(context, hintText!),
        ],
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
    final priceText = sp.price != null
        ? formatVND(sp.price!)
        : (sp.priceLabel != null && sp.priceLabel!.trim().isNotEmpty
            ? sp.priceLabel!
            : 'Liên hệ');

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
                priceText,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: cs.primary,
                ),
              ),
              if (sp.unit != null && sp.unit!.trim().isNotEmpty)
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

  static Widget _messageView(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String message,
    VoidCallback? action,
    String actionLabel = 'Thử lại',
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: color),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 12),
              FilledButton(
                onPressed: action,
                child: Text(actionLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CourtServicesTab extends StatelessWidget {
  const CourtServicesTab({
    super.key,
    required this.pricing,
    required this.services,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
  });

  final List<CourtPricing> pricing;
  final List<CourtServiceItem> services;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      return PricingTableMini._messageView(
        context,
        icon: Icons.error_outline,
        color: Colors.redAccent,
        message: 'Không thể tải thông tin dịch vụ.\n$errorMessage',
        action: onRetry,
        actionLabel: 'Thử lại',
      );
    }

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final pricingItems = pricing
        .map(ServicePrice.fromCourtPricing)
        .where((item) => item.hasPrice)
        .toList(growable: false);

    final serviceItems = services
        .map(ServicePrice.fromCourtService)
        .where((item) => item.name.trim().isNotEmpty)
        .toList(growable: false);

    if (pricingItems.isEmpty && serviceItems.isEmpty) {
      return PricingTableMini._messageView(
        context,
        icon: Icons.info_outline,
        color: Theme.of(context).colorScheme.primary,
        message: 'Sân chưa cập nhật bảng giá hoặc dịch vụ.',
        action: onRetry,
        actionLabel: 'Tải lại',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (pricingItems.isNotEmpty)
          PricingTableMini(
            title: 'Bảng giá theo khung giờ',
            items: pricingItems,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
          ),
        if (pricingItems.isNotEmpty && serviceItems.isNotEmpty)
          const SizedBox(height: 24),
        if (serviceItems.isNotEmpty)
          PricingTableMini(
            title: 'Dịch vụ tại sân',
            items: serviceItems,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            emptyLabel: 'Sân chưa cập nhật dịch vụ.',
            hintText:
                'Giá dịch vụ có thể thay đổi tùy thời điểm. Vui lòng liên hệ quầy lễ tân để biết thêm chi tiết.',
          ),
      ],
    );
  }
}
