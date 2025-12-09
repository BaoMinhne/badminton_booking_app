import 'package:badminton_booking_app/components/my_carousel.dart';
import 'package:badminton_booking_app/components/my_text_field.dart';
import 'package:badminton_booking_app/models/court.dart';
import 'package:badminton_booking_app/models/user_booking_view.dart';
import 'package:badminton_booking_app/pages/court/booking_page.dart';
import 'package:badminton_booking_app/pages/court/court_page.dart';
import 'package:badminton_booking_app/pages/court/court_detail.dart';
import 'package:badminton_booking_app/pages/home/search_page.dart';
import 'package:badminton_booking_app/pages/user/user_booking_history_page.dart';
import 'package:badminton_booking_app/pages/user/user_manager.dart';
import 'package:badminton_booking_app/services/booking_service.dart';
import 'package:badminton_booking_app/services/court_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:badminton_booking_app/utils/currency.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController searchController = TextEditingController();
  final CourtService _courtService = CourtService();
  final BookingService _bookingService = BookingService();
  final _banner = [
    'assets/images/court_cover.jpg',
    'https://picsum.photos/seed/promo1/1200/600',
    'https://picsum.photos/seed/promo2/1200/600',
    'https://picsum.photos/seed/promo3/1200/600',
    'https://picsum.photos/seed/promo4/1200/600',
    'https://picsum.photos/seed/promo5/1200/600',
  ];
  int _bannerIndex = 0;
  bool _isCourtsLoading = false;
  String? _courtError;
  List<Court> _courts = const [];

  bool _isUpcomingLoading = false;
  String? _upcomingError;
  UserBookingView? _upcomingBooking;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      _reloadCourts();
      _loadUpcomingBooking();
    });
  }

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
      body: RefreshIndicator(
        onRefresh: _refreshHome,
        child: CustomScrollView(
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
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SearchPage()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _QuickAction(
                      icon: Icons.history,
                      label: 'Lịch sử',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const UserBookingHistoryPage()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _QuickAction(
                      icon: Icons.favorite_border,
                      label: 'Yêu thích',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CourtPage(
                            initialFilter: CourtFilter.favorites,
                          ),
                        ),
                      ),
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

            // ===== Upcoming booking =====
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: _UpcomingCard(
                  booking: _upcomingBooking,
                  isLoading: _isUpcomingLoading,
                  error: _upcomingError,
                  onTap: _upcomingBooking == null
                      ? null
                      : () => _openBookingDetail(_upcomingBooking!),
                  onCreateTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SearchPage()),
                  ),
                  onRetry: _loadUpcomingBooking,
                ),
              ),
            ),

            // ===== Section: Gần bạn =====
            _SectionHeaderSliver(
              title: 'Gần bạn',
              actionText: 'Xem tất cả',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CourtPage()),
              ),
            ),
            ..._buildCourtsSliver(),

            SliverToBoxAdapter(
                child: SizedBox(
                    height: MediaQuery.of(context).padding.bottom + 16)),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshHome() async {
    await Future.wait([
      _reloadCourts(),
      _loadUpcomingBooking(),
    ]);
  }

  Future<void> _reloadCourts() async {
    setState(() {
      _isCourtsLoading = true;
      _courtError = null;
    });

    try {
      final courts = await _courtService.listCourts(perPage: 24);
      final sorted = List<Court>.of(courts)
        ..sort((a, b) => b.bookingCount.compareTo(a.bookingCount));
      final topCourts = sorted.take(3).toList(growable: false);
      if (!mounted) return;
      setState(() {
        _courts = topCourts;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _courtError = error.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isCourtsLoading = false;
      });
    }
  }

  Future<void> _loadUpcomingBooking() async {
    final userManager = context.read<UserManager>();
    final userId = await userManager.getCurrentUserId();

    setState(() {
      _isUpcomingLoading = true;
      _upcomingError = null;
      _upcomingBooking = null;
    });

    if (userId == null) {
      setState(() {
        _upcomingError = 'Bạn cần đăng nhập để xem lịch đặt sân sắp tới.';
        _isUpcomingLoading = false;
      });
      return;
    }

    try {
      final now = DateTime.now();
      final bookings = await _bookingService.listUserBookings(
        userId: userId,
        startTimeInclusive: now,
      );

      final upcoming = bookings
          .where((b) => b.endTime.isAfter(now))
          .toList(growable: false)
        ..sort((a, b) => a.startTime.compareTo(b.startTime));

      if (!mounted) return;
      setState(() {
        _upcomingBooking = upcoming.isNotEmpty ? upcoming.first : null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _upcomingError = error.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isUpcomingLoading = false;
      });
    }
  }

  Future<void> _openBookingDetail(UserBookingView booking) async {
    try {
      final detail = await _courtService.getCourtDetail(booking.courtId);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BookingPage(detailData: detail),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _toast(context, error.toString());
    }
  }

  List<Widget> _buildCourtsSliver() {
    if (_isCourtsLoading) {
      return [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          ),
        )
      ];
    }

    if (_courtError != null) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent),
                const SizedBox(height: 8),
                Text(
                  _courtError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _reloadCourts,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        )
      ];
    }

    if (_courts.isEmpty) {
      return [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'Chưa có sân nào gần bạn. Hãy thử tìm kiếm để đặt sân nhé!',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        )
      ];
    }

    return [
      SliverList.builder(
        itemCount: _courts.length,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
          child: _CourtCard(court: _courts[i]),
        ),
      ),
    ];
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
  final Court court;
  const _CourtCard({required this.court});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasCoverImage =
        court.coverImageUrl != null && court.coverImageUrl!.isNotEmpty;
    final imageProvider = hasCoverImage
        ? NetworkImage(court.coverImageUrl!) as ImageProvider
        : const AssetImage('assets/images/badminton_logo.jpg');

    final ratingLabel =
        court.rating != null && court.rating! > 0 ? court.rating!.toStringAsFixed(1) : null;
    final distanceLabel = court.distanceKm != null && court.distanceKm! > 0
        ? '${court.distanceKm!.toStringAsFixed(1)}km'
        : null;
    final primaryMeta = [ratingLabel, distanceLabel]
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .join(' • ');
    final nextSlot = court.nextSlotLabel?.trim();
    final nextSlotLabel =
        nextSlot != null && nextSlot.isNotEmpty ? nextSlot : 'Khung giờ đang cập nhật';
    final price = court.pricePerHour != null && court.pricePerHour! > 0
        ? formatVND(court.pricePerHour!)
        : 'Giá đang cập nhật';

    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CourtDetail(court: court),
            ),
          );
        },
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
              child: SizedBox(
                width: 110,
                height: 88,
                child: Image(
                  image: imageProvider,
                  fit: BoxFit.cover,
                ),
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
                          primaryMeta.isNotEmpty ? primaryMeta : 'Chưa có đánh giá',
                        ),
                        const Spacer(),
                        Text(price,
                            style: TextStyle(
                                color: cs.primary, fontWeight: FontWeight.w800)),
                        const Text('/giờ', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.schedule,
                            size: 16, color: cs.onSurface.withOpacity(0.7)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            nextSlotLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: cs.onSurface.withOpacity(0.7)),
                          ),
                        ),
                      ],
                    ),
                    if (court.bookingCount > 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.trending_up,
                              size: 16, color: cs.primary.withOpacity(0.85)),
                          const SizedBox(width: 6),
                          Text(
                            '${court.bookingCount} lượt đặt',
                            style: TextStyle(
                              color: cs.onSurface.withOpacity(0.75),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    ],
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

class _UpcomingCard extends StatelessWidget {
  final UserBookingView? booking;
  final bool isLoading;
  final String? error;
  final VoidCallback? onTap;
  final VoidCallback? onCreateTap;
  final VoidCallback? onRetry;
  const _UpcomingCard({
    required this.booking,
    required this.isLoading,
    this.error,
    this.onTap,
    this.onCreateTap,
    this.onRetry,
  });
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cs.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: const [
            CircularProgressIndicator(),
            SizedBox(width: 12),
            Text('Đang kiểm tra lịch sắp tới...'),
          ],
        ),
      );
    }

    if (error != null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cs.errorContainer.withOpacity(0.7),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, color: cs.onErrorContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    error!,
                    style: TextStyle(
                      color: cs.onErrorContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ],
        ),
      );
    }

    if (booking == null) {
      return InkWell(
        onTap: onCreateTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: cs.surfaceVariant.withOpacity(0.65),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.event_busy,
                    color: cs.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Chưa có lịch chơi',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Đặt sân ngay để không bỏ lỡ khung giờ đẹp.',
                        style: TextStyle(height: 1.3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      );
    }

    final highlight = true;
    final textColor = cs.onPrimary;
    final subtitleColor = cs.onPrimary.withOpacity(0.8);
    final dateFormat = DateFormat('HH:mm, dd/MM');
    final location = booking!.courtLocation ?? 'Địa điểm đang cập nhật';
    final unitLabel = booking!.courtUnitLabel;
    final timeRange =
        '${dateFormat.format(booking!.startTime.toLocal())} – ${dateFormat.format(booking!.endTime.toLocal())}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              cs.primary,
              cs.primary.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
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
                  color: cs.onPrimary.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.event_available,
                  color: cs.onPrimary,
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
                      booking!.courtName ?? 'Lịch chơi sắp tới',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      unitLabel == null || unitLabel.isEmpty
                          ? '$location • $timeRange'
                          : '$location • $unitLabel • $timeRange',
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
