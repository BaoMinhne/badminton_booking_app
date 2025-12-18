import 'package:badminton_booking_app/components/my_court.dart';
import 'package:badminton_booking_app/models/booking.dart';
import 'package:badminton_booking_app/models/court.dart';
import 'package:badminton_booking_app/models/court_detail.dart';
import 'package:badminton_booking_app/pages/court/court_manager.dart';
import 'package:badminton_booking_app/pages/court/favorite_court_manager.dart';
import 'package:badminton_booking_app/services/booking_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum CourtFilter { newest, favorites }

enum _AvailabilityFilter { openSlot, nearlyFull }

enum _OpeningDayPart { morning, afternoon, evening }

class TimeOfDayRange {
  final TimeOfDay start;
  final TimeOfDay end;

  const TimeOfDayRange({
    required this.start,
    required this.end,
  });
}

class CourtPage extends StatefulWidget {
  const CourtPage({super.key, this.initialFilter = CourtFilter.newest});

  final CourtFilter initialFilter;

  @override
  State<CourtPage> createState() => _CourtPageState();
}

class _CourtPageState extends State<CourtPage> {
  late CourtFilter _selectedFilter;
  var _minCourtQuantity = 0.0;
  int? _quantityQuickUpperBound;
  bool _openNowOnly = false;
  _OpeningDayPart? _dayPartFilter;
  TimeOfDayRange? _desiredPlayRange;

  DateTime? _selectedDate;
  TimeOfDayRange? _selectedSlotRange;
  _AvailabilityFilter? _availabilityFilter;

  final Map<String, _CourtFilterMeta> _courtMetadata = {};
  bool _isMetadataLoading = false;
  String? _metadataError;

  final Map<String, _CourtAvailabilitySnapshot> _availabilityByCourt = {};
  bool _isAvailabilityLoading = false;
  String? _availabilityError;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
    Future.microtask(() {
      context.read<FavoriteCourtManager>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final courtManager = context.watch<CourtManager>();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Courts'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              context.read<CourtManager>().refresh(),
              context.read<FavoriteCourtManager>().refresh(),
            ]);
            setState(() {
              _courtMetadata.clear();
              _availabilityByCourt.clear();
            });
          },
          child: Builder(
            builder: (context) {
              if (courtManager.isLoading) {
                return _wrapScrollable(
                  const Center(child: CircularProgressIndicator()),
                );
              }
              if (courtManager.errorMessage != null) {
                return _wrapScrollable(
                  _buildErrorState(context, courtManager.errorMessage!),
                );
              }
              if (courtManager.courts.isEmpty) {
                return _wrapScrollable(_buildEmptyState(context));
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
    if (_selectedFilter == CourtFilter.favorites && favoriteManager.isLoading) {
      return _wrapScrollable(
        Column(
          children: [
            _buildHeroHeader(
              context,
              favoriteManager.favoriteCourtIds.length,
              favoriteManager,
            ),
            _buildFilterChips(context, favoriteManager),
            const SizedBox(height: 32),
            const Center(child: CircularProgressIndicator()),
          ],
        ),
      );
    }

    final filteredCourts = _applyFilter(courts, favoriteManager);
    final recommended = filteredCourts.take(5).toList();
    final remainingAfterRecommended =
        filteredCourts.skip(recommended.length).toList();
    final nearby = remainingAfterRecommended.take(5).toList();
    final popular = remainingAfterRecommended.skip(nearby.length).toList();

    final sections = <Widget>[
      _buildHeroHeader(context, filteredCourts.length, favoriteManager),
      _buildFilterChips(context, favoriteManager),
      _buildAdvancedFilterLauncher(context),
      if (_needsOpeningHoursData || _needsAvailabilityData)
        _buildFilterStatus(context),
      const SizedBox(height: 16),
      _buildCourtSection(context, 'Recommended for You', recommended),
    ];

    if (nearby.isNotEmpty) {
      sections.add(_buildCourtSection(context, 'Courts Near You', nearby));
    }

    if (popular.isNotEmpty) {
      sections.add(_buildCourtSection(context, 'Popular Courts', popular));
    }

    if (_selectedFilter == CourtFilter.favorites && filteredCourts.isEmpty) {
      sections
        ..clear()
        ..addAll([
          _buildHeroHeader(context, filteredCourts.length, favoriteManager),
          _buildFilterChips(context, favoriteManager),
          _buildEmptyFavoriteState(context),
        ]);
    }

    sections.add(const SizedBox(height: 100));

    return _wrapScrollable(
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: sections,
        ),
      ),
    );
  }

  Widget _wrapScrollable(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final minHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : MediaQuery.of(context).size.height;
        final minWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight, minWidth: minWidth),
            child: Align(
              alignment: Alignment.topCenter,
              child: child,
            ),
          ),
        );
      },
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
                    'Discover & book courts now',
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
                        label: '$courtCount courts available',
                      ),
                      const SizedBox(width: 8),
                      _buildStatPill(
                        context,
                        icon: Icons.favorite,
                        label:
                            '${favoriteManager.favoriteCourtIds.length} favorites',
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

  Widget _buildFilterChips(
    BuildContext context,
    FavoriteCourtManager favoriteManager,
  ) {
    final filters = [
    (CourtFilter.newest, 'Newest', Icons.auto_awesome),
    (CourtFilter.favorites, 'Favorites', Icons.favorite),
    ];
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (_, index) {
          final (filter, label, icon) = filters[index];
          final isSelected = _selectedFilter == filter;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color:
                  isSelected ? colorScheme.primaryContainer : colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              borderRadius: BorderRadius.circular(24),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: isSelected
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: isSelected
                          ? colorScheme.onPrimaryContainer
                          : null,
                    ),
                  ),
                  if (filter == CourtFilter.favorites) ...[
                    const SizedBox(width: 6),
                    _buildFavoriteBadge(
                      colorScheme,
                      favoriteManager.favoriteCourtIds.length,
                    ),
                  ]
                ],
              ),
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

  Widget _buildAdvancedFilterLauncher(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Advanced filters',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: Icon(Icons.tune, color: colorScheme.primary),
            style: OutlinedButton.styleFrom(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              backgroundColor: colorScheme.surfaceVariant,
              side: BorderSide(color: colorScheme.outlineVariant),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            label: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Open filters',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 2),
                Text(
                  'Court count, opening hours, open slots',
                  style: TextStyle(fontSize: 12),
                )
              ],
            ),
            onPressed: () => _openAdvancedFiltersBottomSheet(context),
          ),
        ],
      ),
    );
  }

  void _openAdvancedFiltersBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.85,
            minChildSize: 0.45,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: _buildAdvancedFiltersContent(context),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAdvancedFiltersContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_alt, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Advanced filters',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuantityFilterChip('1–3 courts', () {
                _handleFilterChanged(() {
                  _minCourtQuantity = 1;
                  _quantityQuickUpperBound = 3;
                });
              },
                  isSelected:
                      _minCourtQuantity == 1 && _quantityQuickUpperBound == 3),
              _buildQuantityFilterChip('4–6 courts', () {
                _handleFilterChanged(() {
                  _minCourtQuantity = 4;
                  _quantityQuickUpperBound = 6;
                });
              },
                  isSelected:
                      _minCourtQuantity == 4 && _quantityQuickUpperBound == 6),
              _buildQuantityFilterChip('≥ 7 courts', () {
                _handleFilterChanged(() {
                  _minCourtQuantity = 7;
                  _quantityQuickUpperBound = null;
                });
              },
                  isSelected:
                      _minCourtQuantity == 7 && _quantityQuickUpperBound == null),
              _buildToggleChip(
                context,
                label: 'Open now',
                icon: Icons.access_time,
                value: _openNowOnly,
                onChanged: (value) => _handleFilterChanged(() {
                  _openNowOnly = value;
                }),
              ),
              _buildToggleChip(
                context,
                label: 'Morning',
                icon: Icons.wb_sunny_outlined,
                value: _dayPartFilter == _OpeningDayPart.morning,
                onChanged: (value) => _handleFilterChanged(() {
                  _dayPartFilter = value ? _OpeningDayPart.morning : null;
                }),
              ),
              _buildToggleChip(
                context,
                label: 'Afternoon',
                icon: Icons.wb_twilight,
                value: _dayPartFilter == _OpeningDayPart.afternoon,
                onChanged: (value) => _handleFilterChanged(() {
                  _dayPartFilter = value ? _OpeningDayPart.afternoon : null;
                }),
              ),
              _buildToggleChip(
                context,
                label: 'Evening',
                icon: Icons.nightlight_outlined,
                value: _dayPartFilter == _OpeningDayPart.evening,
                onChanged: (value) => _handleFilterChanged(() {
                  _dayPartFilter = value ? _OpeningDayPart.evening : null;
                }),
              ),
              _buildToggleChip(
                context,
                label: 'Has openings',
                icon: Icons.event_available,
                value: _availabilityFilter == _AvailabilityFilter.openSlot,
                onChanged: (value) => _handleFilterChanged(() {
                  _availabilityFilter =
                      value ? _AvailabilityFilter.openSlot : null;
                }),
              ),
              _buildToggleChip(
                context,
                label: 'Nearly full',
                icon: Icons.speed,
                value: _availabilityFilter == _AvailabilityFilter.nearlyFull,
                onChanged: (value) => _handleFilterChanged(() {
                  _availabilityFilter =
                      value ? _AvailabilityFilter.nearlyFull : null;
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSliderCard(context),
          const SizedBox(height: 8),
          _buildTimePickers(context),
        ],
      ),
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
              'Unable to load courts',
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
              label: const Text('Retry'),
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
              'No courts available right now',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Please check back later!',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFavoriteState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_border,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'No favorite courts yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Add courts you like to see them here!',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteBadge(ColorScheme colorScheme, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }

  bool get _needsOpeningHoursData =>
      _openNowOnly || _dayPartFilter != null || _desiredPlayRange != null;

  bool get _needsAvailabilityData =>
      _availabilityFilter != null &&
      _selectedDate != null &&
      _selectedSlotRange != null;

  void _kickOffMetadataLoad(List<Court> courts) async {
    if (!_needsOpeningHoursData && !_needsAvailabilityData) return;
    final missing = courts
        .where((court) => !_courtMetadata.containsKey(court.id))
        .toList();
    if (missing.isEmpty) return;

    setState(() {
      _isMetadataLoading = true;
      _metadataError = null;
    });

    try {
      final service = context.read<CourtManager>().courtService;
      for (final court in missing) {
        final detail = await service.getCourtDetail(court.id);
        _courtMetadata[court.id] = _CourtFilterMeta(
          openingHours: detail.openingHours,
          units: detail.units,
        );
      }
    } catch (error) {
      setState(() {
        _metadataError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isMetadataLoading = false;
        });
      }
    }
  }

  void _refreshAvailabilityIfNeeded(List<Court> courts) async {
    if (!_needsAvailabilityData) return;
    setState(() {
      _isAvailabilityLoading = true;
      _availabilityError = null;
    });

    final bookingService = BookingService();
    final targetDate = _selectedDate!;
    final targetRange = _selectedSlotRange!;
    final nextSnapshots = <String, _CourtAvailabilitySnapshot>{};

    try {
      for (final court in courts) {
        final units = _courtMetadata[court.id]?.activeUnits ?? court.courtQuantity;
        if (units <= 0) continue;

        final bookings = await bookingService.listBookings(
          courtId: court.id,
          date: targetDate,
        );

        final startUtc = _combine(targetDate, targetRange.start).toUtc();
        final endUtc = _combine(targetDate, targetRange.end).toUtc();

        final overlapping = bookings.where((booking) {
          if (booking.status == BookingStatus.cancelled ||
              booking.status == BookingStatus.expired) {
            return false;
          }
          return booking.startTime.isBefore(endUtc) &&
              booking.endTime.isAfter(startUtc);
        }).toList();

        final double utilization =
            units == 0 ? 0.0 : overlapping.length / units;
        nextSnapshots[court.id] = _CourtAvailabilitySnapshot(
          activeUnits: units,
          overlappingBookings: overlapping.length,
          utilization: utilization,
        );
      }

      if (mounted) {
        setState(() {
          _availabilityByCourt
            ..clear()
            ..addAll(nextSnapshots);
        });
      }
    } catch (error) {
      setState(() {
        _availabilityError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isAvailabilityLoading = false;
        });
      }
    }
  }

  DateTime _combine(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  bool _matchesQuantityFilter(Court court) {
    final quantity = court.courtQuantity;
    if (quantity < _minCourtQuantity) return false;
    if (_quantityQuickUpperBound != null &&
        quantity > _quantityQuickUpperBound!) {
      return false;
    }
    return true;
  }

  bool _matchesOpeningFilter(String courtId) {
    if (!_needsOpeningHoursData) return true;
    final meta = _courtMetadata[courtId];
    if (meta == null || meta.openingHours.isEmpty) {
      return _isMetadataLoading ? true : !_openNowOnly;
    }

    final now = TimeOfDay.fromDateTime(DateTime.now());
    final desiredRange = _desiredPlayRange;

    for (final opening in meta.openingHours) {
      final openTime = _parseTime(opening.openTime);
      final closeTime = _parseTime(opening.closeTime);
      if (openTime == null || closeTime == null) continue;

      if (_openNowOnly && !_isWithinRange(openTime, closeTime, now, now)) {
        continue;
      }

      if (_dayPartFilter != null &&
          !_matchesDayPart(openTime, closeTime, _dayPartFilter!)) {
        continue;
      }

      if (desiredRange != null &&
          !_isWithinRange(openTime, closeTime, desiredRange.start, desiredRange.end)) {
        continue;
      }

      return true;
    }

    return false;
  }

  bool _matchesAvailabilityFilter(String courtId) {
    if (!_needsAvailabilityData) return true;
    final snapshot = _availabilityByCourt[courtId];
    if (snapshot == null) {
      if (_isAvailabilityLoading) return true;
      return false;
    }

    switch (_availabilityFilter) {
      case _AvailabilityFilter.openSlot:
        return snapshot.overlappingBookings < snapshot.activeUnits;
      case _AvailabilityFilter.nearlyFull:
        return snapshot.utilization >= 0.7 && snapshot.utilization <= 0.9;
      case null:
        return true;
    }
  }

  bool _matchesDayPart(int openMinutes, int closeMinutes, _OpeningDayPart part) {
    const morningStart = 5 * 60;
    const morningEnd = 12 * 60;
    const afternoonStart = morningEnd;
    const afternoonEnd = 17 * 60;
    const eveningEnd = 23 * 60;
    switch (part) {
      case _OpeningDayPart.morning:
        return openMinutes <= morningStart && closeMinutes >= morningEnd;
      case _OpeningDayPart.afternoon:
        return openMinutes <= afternoonStart && closeMinutes >= afternoonEnd;
      case _OpeningDayPart.evening:
        return openMinutes <= afternoonEnd && closeMinutes >= eveningEnd;
    }
  }

  bool _isWithinRange(
    int openMinutes,
    int closeMinutes,
    TimeOfDay start,
    TimeOfDay end,
  ) {
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    return openMinutes <= startMinutes && closeMinutes >= endMinutes;
  }

  int? _parseTime(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return hour * 60 + minute;
  }

  String get _slotRangeLabel {
    if (_selectedSlotRange == null) return 'Select time';
    return '${_selectedSlotRange!.start.format(context)} – ${_selectedSlotRange!.end.format(context)}';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  Future<TimeOfDayRange?> _pickTimeRange(
    BuildContext context,
    TimeOfDayRange? initial,
  ) async {
    final now = TimeOfDay.now();
    final first = await showTimePicker(
      context: context,
      initialTime: initial?.start ?? now,
    );
    if (first == null) return null;
    final second = await showTimePicker(
      context: context,
      initialTime: initial?.end ?? first.replacing(hour: (first.hour + 2) % 24),
    );
    if (second == null) return null;
    return TimeOfDayRange(start: first, end: second);
  }

  void _handleFilterChanged(VoidCallback updater) {
    setState(updater);
    final courts = context.read<CourtManager>().courts;
    _kickOffMetadataLoad(courts);
    _refreshAvailabilityIfNeeded(courts);
  }

  Widget _buildQuantityFilterChip(
    String label,
    VoidCallback onPressed, {
    required bool isSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onPressed(),
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      labelStyle: TextStyle(
        fontWeight: FontWeight.w700,
        color: isSelected
            ? Theme.of(context).colorScheme.onPrimaryContainer
            : null,
      ),
    );
  }

  Widget _buildToggleChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: value ? colorScheme.onPrimary : null),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: value,
      onSelected: onChanged,
      backgroundColor: colorScheme.surfaceVariant,
      selectedColor: colorScheme.primary,
      checkmarkColor: colorScheme.onPrimary,
      labelStyle: TextStyle(
        color: value ? colorScheme.onPrimary : null,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildSliderCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.stacked_line_chart, size: 18),
                  const SizedBox(width: 6),
                  const Text(
                    'Minimum court count',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              Text(
                _minCourtQuantity.floor().toString(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Slider(
            value: _minCourtQuantity.clamp(0, 12),
            min: 0,
            max: 12,
            divisions: 12,
            label: _minCourtQuantity.toStringAsFixed(0),
            onChanged: (value) {
              _handleFilterChanged(() {
                _minCourtQuantity = value;
                _quantityQuickUpperBound = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimePickers(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Time window you want to play',
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildFilledButton(
                context,
                icon: Icons.calendar_today,
                label: _selectedDate == null
                    ? 'Select date'
                    : _formatDate(_selectedDate!),
                onTap: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? now,
                    firstDate: now,
                    lastDate: now.add(const Duration(days: 90)),
                  );
                  if (picked != null) {
                    _handleFilterChanged(() {
                      _selectedDate = picked;
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildFilledButton(
                context,
                icon: Icons.schedule,
                label: _slotRangeLabel,
                onTap: () async {
                  final range = await _pickTimeRange(context, _selectedSlotRange);
                  if (range != null) {
                    _handleFilterChanged(() {
                      _selectedSlotRange = range;
                      _desiredPlayRange ??= range;
                    });
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text('Preferred opening hours',
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        _buildFilledButton(
          context,
          icon: Icons.timelapse,
          label: _desiredPlayRange == null
              ? 'Select time range'
              : '${_desiredPlayRange!.start.format(context)} – ${_desiredPlayRange!.end.format(context)}',
          onTap: () async {
            final range = await _pickTimeRange(context, _desiredPlayRange);
            if (range != null) {
              _handleFilterChanged(() {
                _desiredPlayRange = range;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildFilledButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceVariant,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.edit_calendar, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterStatus(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLoading =
        (_needsOpeningHoursData && _isMetadataLoading) || _isAvailabilityLoading;
    final error = _metadataError ?? _availabilityError;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isLoading ? Icons.downloading : Icons.info_outline,
            color: isLoading ? colorScheme.primary : colorScheme.onSurface,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLoading
                      ? 'Loading opening hours & open slots...'
                      : 'Time & slot filters are ready',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                if (error != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    error,
                    style: TextStyle(color: colorScheme.error),
                  ),
                ]
              ],
            ),
          ),
          if (isLoading) const SizedBox(width: 8),
          if (isLoading) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          if (error != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                final courts = context.read<CourtManager>().courts;
                _kickOffMetadataLoad(courts);
                _refreshAvailabilityIfNeeded(courts);
              },
            ),
        ],
      ),
    );
  }

  List<Court> _applyFilter(
    List<Court> courts,
    FavoriteCourtManager favoriteManager,
  ) {
    List<Court> base;
    switch (_selectedFilter) {
      case CourtFilter.favorites:
        final favoriteIds = favoriteManager.favoriteCourtIds;
        base = courts
            .where((court) => favoriteIds.contains(court.id))
            .toList(growable: false);
        break;
      case CourtFilter.newest:
        base = [...courts];
        base.sort((a, b) {
          final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });
        break;
    }

    return base
        .where(_matchesQuantityFilter)
        .where((court) => _matchesOpeningFilter(court.id))
        .where((court) => _matchesAvailabilityFilter(court.id))
        .toList(growable: false);
  }
}

class _CourtFilterMeta {
  _CourtFilterMeta({
    this.openingHours = const [],
    this.units = const [],
  });

  final List<CourtOpeningHour> openingHours;
  final List<CourtUnit> units;

  int get activeUnits => units.where((unit) => unit.isActive).length;
}

class _CourtAvailabilitySnapshot {
  _CourtAvailabilitySnapshot({
    required this.activeUnits,
    required this.overlappingBookings,
    required this.utilization,
  });

  final int activeUnits;
  final int overlappingBookings;
  final double utilization;
}
