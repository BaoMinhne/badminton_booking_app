import 'package:flutter/material.dart';

class MyCourtCard extends StatelessWidget {
  const MyCourtCard({
    super.key,
    required this.title,
    required this.distanceText, // ví dụ: (606.8m)
    required this.address,
    required this.openHours, // ví dụ: 05:00 - 22:00
    required this.phone, // ví dụ: 0292 2246 777
    required this.coverImage,
    required this.sportLogo,
    this.onTap,
    this.onBookPressed,
    this.onFavoritePressed,
    this.onRoutePressed,
    this.isFavorite = false,
    this.showDailyBadge = true,
    this.showEventBadge = true,
  });

  final String title;
  final String distanceText;
  final String address;
  final String openHours;
  final String phone;

  final ImageProvider coverImage;
  final ImageProvider sportLogo;

  final VoidCallback? onTap;
  final VoidCallback? onBookPressed;
  final VoidCallback? onFavoritePressed;
  final VoidCallback? onRoutePressed;

  final bool isFavorite;
  final bool showDailyBadge;
  final bool showEventBadge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final onPrimary = theme.colorScheme.onPrimary;
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.all(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Material(
              color: surface,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ẢNH BÌA + BADGE + ACTION
                  Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image(
                          image: coverImage,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      // Badge góc trái
                      if (showDailyBadge || showEventBadge)
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Row(
                            children: [
                              if (showDailyBadge)
                                _chip("Đơn ngày", primary, onPrimary),
                              if (showEventBadge) const SizedBox(width: 8),
                              if (showEventBadge)
                                _chip("Sự kiện", const Color(0xFFE69BE6),
                                    Colors.white),
                            ],
                          ),
                        ),
                      // Nút hành động góc phải
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Row(
                          children: [
                            _circleBtn(
                              icon: isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              onTap: onFavoritePressed,
                            ),
                            const SizedBox(width: 10),
                            _circleBtn(
                              icon: Icons.alt_route,
                              onTap: onRoutePressed,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // THÔNG TIN
                  Container(
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(20)),
                    ),
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // logo môn
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            image: DecorationImage(
                                image: sportLogo, fit: BoxFit.contain),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // text info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Tiêu đề + địa chỉ (dòng rút gọn)
                              RichText(
                                text: TextSpan(
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    height: 1.2,
                                    color: const Color(
                                        0xFF0E5A3A), // xanh đậm giống ảnh
                                    fontWeight: FontWeight.w800,
                                  ),
                                  children: [
                                    TextSpan(text: "$title\n"),
                                    TextSpan(
                                      text: "$distanceText  ",
                                      style: const TextStyle(
                                        color: Color(
                                            0xFFE76E37), // cam cho distance
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    TextSpan(
                                      text: address,
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        color: onSurface.withOpacity(0.75),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),

                              // giờ + phone
                              Row(
                                children: [
                                  const Icon(Icons.schedule, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    openHours,
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(width: 14),
                                  const Icon(Icons.call, size: 18),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      phone,
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        color: primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 10),

                        // Nút đặt lịch
                        ElevatedButton(
                          onPressed: onBookPressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFFD7A734), // vàng như ảnh
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            "ĐẶT LỊCH",
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _circleBtn({required IconData icon, VoidCallback? onTap}) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 22, color: const Color(0xFF0E5A3A)),
        ),
      ),
    );
  }
}
