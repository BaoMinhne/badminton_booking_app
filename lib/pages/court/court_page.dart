import 'package:badminton_booking_app/components/my_court.dart';
import 'package:badminton_booking_app/models/court.dart';
import 'package:badminton_booking_app/pages/court/court_manager.dart';
import 'package:badminton_booking_app/pages/court/favorite_court_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CourtPage extends StatefulWidget {
  CourtPage({super.key});

  @override
  State<CourtPage> createState() => _CourtPageState();
}

class _CourtPageState extends State<CourtPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<FavoriteCourtManager>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final courtManager = context.watch<CourtManager>();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              context.read<CourtManager>().refresh(),
              context.read<FavoriteCourtManager>().refresh(),
            ]);
          },
          child: Builder(
            builder: (context) {
              if (courtManager.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (courtManager.errorMessage != null) {
                return _buildErrorState(context, courtManager.errorMessage!);
              }
              if (courtManager.courts.isEmpty) {
                return _buildEmptyState(context);
              }

              return _buildContent(
                context,
                courtManager.courts,
                context.watch<FavoriteCourtManager>(),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<Court> courts,
    FavoriteCourtManager favoriteManager,
  ) {
    final recommended = courts.take(5).toList();
    final remainingAfterRecommended = courts.skip(recommended.length).toList();
    final nearby = remainingAfterRecommended.take(5).toList();
    final popular = remainingAfterRecommended.skip(nearby.length).toList();

    final sections = <Widget>[
      _buildHeroHeader(context, courts.length, favoriteManager),
      _buildFilterChips(context),
      const SizedBox(height: 16),
      _buildCourtSection(context, 'Có Thể Bạn Sẽ Thích', recommended),
    ];

    if (nearby.isNotEmpty) {
      sections.add(_buildCourtSection(context, 'Sân Gần Bạn', nearby));
    }

    if (popular.isNotEmpty) {
      sections.add(_buildCourtSection(context, 'Sân Phổ Biến', popular));
    }

    sections.add(const SizedBox(height: 100));

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: sections,
        ),
      ),
    );
  }

  Widget _buildHeroHeader(
    BuildContext context,
    int courtCount,
    FavoriteCourtManager favoriteManager,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary.withOpacity(0.9),
              colorScheme.primary.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.25),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'COURT',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: colorScheme.onPrimary.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Khám phá & đặt sân ngay',
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildStatPill(
                        context,
                        icon: Icons.sports_tennis,
                        label: '$courtCount sân khả dụng',
                      ),
                      const SizedBox(width: 8),
                      _buildStatPill(
                        context,
                        icon: Icons.favorite,
                        label:
                            '${favoriteManager.favoriteCourtIds.length} yêu thích',
                      ),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.16),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(12),
              child: const Icon(
                Icons.flash_on,
                size: 30,
                color: Colors.white,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatPill(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.onPrimary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colorScheme.onPrimary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    final filters = [
      ('Mới nhất', Icons.auto_awesome),
      ('Gần tôi', Icons.location_on_outlined),
    ];
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (_, index) {
          final (label, icon) = filters[index];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                )
              ],
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemCount: filters.length,
      ),
    );
  }

  Widget _buildCourtSection(
    BuildContext context,
    String title,
    List<Court> courts,
  ) {
    if (courts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 5,
              height: 24,
              color: Theme.of(context).colorScheme.primary,
              margin: const EdgeInsets.only(
                left: 12,
                right: 8,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: courts
                .map((court) => MyCourt(court: court))
                .toList(growable: false),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              'Không thể tải danh sách sân',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.read<CourtManager>().refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sports_tennis,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Hiện chưa có sân nào',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy quay lại sau nhé!',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
