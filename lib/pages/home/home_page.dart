import 'package:badminton_booking_app/components/my_carousel.dart';
import 'package:badminton_booking_app/components/my_text_field.dart';
import 'package:badminton_booking_app/pages/home/search_page.dart';
import 'package:badminton_booking_app/utils/currency.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController searchController = TextEditingController();
  final _banner = [
    'assets/images/court_cover.jpg',
    'https://picsum.photos/seed/promo1/1200/600',
    'https://picsum.photos/seed/promo2/1200/600',
    'https://picsum.photos/seed/promo3/1200/600',
    'https://picsum.photos/seed/promo4/1200/600',
    'https://picsum.photos/seed/promo5/1200/600',
  ];
  int _bannerIndex = 0;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Courtify'),
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          // ===== Search + Location + Quick filters =====
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _GreetingHeader(
                    onNotificationTap: () =>
                        _toast(context, 'Thông báo sẽ sớm có mặt!'),
                  ),
                  const SizedBox(height: 18),
                  MyTextfield(
                    hintText: "Search for courts...",
                    controller: searchController,
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: IconButton(
                      onPressed: () => _toast(
                          context, 'Bộ lọc nâng cao đang được hoàn thiện'),
                      icon: const Icon(Icons.tune_rounded),
                    ),
                    isReadOnly: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SearchPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // ===== Quick actions =====
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  _QuickAction(
                    icon: Icons.sports_tennis,
                    label: 'Đặt sân',
                    onTap: () => _toast(context, 'Đi tới màn đặt sân (demo)'),
                  ),
                  const SizedBox(width: 12),
                  _QuickAction(
                    icon: Icons.history,
                    label: 'Lịch sử',
                    onTap: () => _toast(context, 'Mở Lịch sử đặt sân'),
                  ),
                  const SizedBox(width: 12),
                  _QuickAction(
                    icon: Icons.favorite_border,
                    label: 'Yêu thích',
                    onTap: () => _toast(context, 'Mở danh sách yêu thích'),
                  ),
                ],
              ),
            ),
          ),

          // ===== Promo carousel =====
          SliverToBoxAdapter(
            child: MyCarousel(
              images: _banner,
              onIndexChanged: (i) => setState(() => _bannerIndex = i),
            ),
          ),

          // ===== Upcoming booking (demo) =====
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: _UpcomingCard(
                hasBooking: true, // đổi false để thấy CTA rỗng
                onTap: () => _toast(context, 'Mở chi tiết lịch sắp tới'),
              ),
            ),
          ),

          // ===== Section: Gần bạn =====
          _SectionHeaderSliver(
              title: 'Gần bạn', actionText: 'Xem tất cả', onTap: () {}),
          SliverList.builder(
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
              child: _CourtCard(court: kHomeCourts[i]),
            ),
            itemCount: kHomeCourts.length,
          ),

          SliverToBoxAdapter(
              child:
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 16)),
        ],
      ),
    );
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

/// ===================== Small widgets =====================
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  const _SearchBar({required this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Tìm sân, quận/huyện…',
        prefixIcon: const Icon(Icons.search),
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  final VoidCallback onNotificationTap;
  const _GreetingHeader({required this.onNotificationTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.location_on_rounded, color: cs.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Xin chào!',
                style: textTheme.labelLarge?.copyWith(
                  color: cs.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.place_outlined,
                      size: 18, color: cs.primary.withOpacity(0.9)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Cần Thơ, Việt Nam',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onNotificationTap,
          icon: Icon(Icons.notifications_none_rounded,
              color: cs.onSurface.withOpacity(0.7)),
          splashRadius: 22,
        ),
      ],
    );
  }
}

class _ChipBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ChipBtn({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.primary.withOpacity(0.2)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: cs.primary),
        const SizedBox(width: 6),
        Text(label),
      ]),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                cs.primary.withOpacity(0.95),
                cs.primary.withOpacity(0.75),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withOpacity(0.2),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cs.onPrimary.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, size: 20, color: cs.onPrimary),
                ),
                const SizedBox(height: 16),
                Text(
                  label,
                  style: TextStyle(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeaderSliver extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onTap;
  const _SectionHeaderSliver(
      {required this.title, this.actionText, this.onTap});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(40),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            if (actionText != null)
              TextButton(
                onPressed: onTap,
                style: TextButton.styleFrom(
                  foregroundColor: cs.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(actionText!),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, size: 18),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CourtCard extends StatelessWidget {
  final HomeCourt court;
  const _CourtCard({required this.court});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isAsset = !court.image.startsWith('http');

    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Mở chi tiết: ${court.name}')),
          );
        },
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12)),
              child: SizedBox(
                width: 110,
                height: 88,
                child: isAsset
                    ? Image.asset(court.image, fit: BoxFit.cover)
                    : Image.network(court.image, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 12, top: 10, bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(court.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                            '${court.rating.toStringAsFixed(1)} • ${court.distanceKm.toStringAsFixed(1)}km'),
                        const Spacer(),
                        Text(formatVND(court.pricePerHour),
                            style: TextStyle(
                                color: cs.primary,
                                fontWeight: FontWeight.w800)),
                        const Text('/giờ', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.schedule,
                            size: 16, color: cs.onSurface.withOpacity(0.7)),
                        const SizedBox(width: 4),
                        Text(court.nextSlotLabel,
                            style: TextStyle(
                                color: cs.onSurface.withOpacity(0.7))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ===================== Mock data & helpers =====================
class HomeCourt {
  final String name;
  final String image; // asset or url
  final double rating;
  final double distanceKm;
  final int pricePerHour;
  final String nextSlotLabel;
  HomeCourt({
    required this.name,
    required this.image,
    required this.rating,
    required this.distanceKm,
    required this.pricePerHour,
    required this.nextSlotLabel,
  });
}

final kHomeCourts = <HomeCourt>[
  HomeCourt(
    name: 'Minh Nghĩa Badminton',
    image: 'assets/images/court_cover.jpg',
    rating: 4.7,
    distanceKm: 1.2,
    pricePerHour: 60000,
    nextSlotLabel: 'Còn 18:00–19:00 hôm nay',
  ),
  HomeCourt(
    name: 'NTĐ Quận Ninh Kiều',
    image: 'https://picsum.photos/seed/court21/1200/800',
    rating: 4.5,
    distanceKm: 2.6,
    pricePerHour: 70000,
    nextSlotLabel: '19:00–20:00 hôm nay',
  ),
  HomeCourt(
    name: 'Sân Cầu Lông Xuân Khánh',
    image: 'https://picsum.photos/seed/court22/1200/800',
    rating: 4.2,
    distanceKm: 3.1,
    pricePerHour: 55000,
    nextSlotLabel: '17:00–18:00 ngày mai',
  ),
];

class _UpcomingCard extends StatelessWidget {
  final bool hasBooking;
  final VoidCallback onTap;
  const _UpcomingCard({required this.hasBooking, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final highlight = hasBooking;
    final textColor = highlight ? cs.onPrimary : cs.onSurface;
    final subtitleColor = highlight
        ? cs.onPrimary.withOpacity(0.8)
        : cs.onSurface.withOpacity(0.7);

    return InkWell(
      onTap: hasBooking ? onTap : null,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        decoration: BoxDecoration(
          gradient: highlight
              ? LinearGradient(
                  colors: [
                    cs.primary,
                    cs.primary.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: highlight ? null : cs.surfaceVariant.withOpacity(0.65),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            if (highlight)
              BoxShadow(
                color: cs.primary.withOpacity(0.18),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: highlight
                      ? cs.onPrimary.withOpacity(0.18)
                      : cs.primary.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  highlight ? Icons.event_available : Icons.event_busy,
                  color: highlight ? cs.onPrimary : cs.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      highlight ? 'Lịch chơi sắp tới' : 'Chưa có lịch chơi',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      highlight
                          ? 'Bạn có lịch Minh Nghĩa Badminton • 19:00–21:00 hôm nay'
                          : 'Đặt sân ngay để không bỏ lỡ khung giờ đẹp.',
                      style: TextStyle(
                        color: subtitleColor,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.chevron_right, color: textColor),
            ],
          ),
        ),
      ),
    );
  }
}
