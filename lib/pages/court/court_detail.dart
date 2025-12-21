import 'package:badminton_booking_app/models/booking.dart';
import 'package:badminton_booking_app/models/court.dart';
import 'package:badminton_booking_app/models/court_detail.dart';
import 'package:badminton_booking_app/pages/court/booking_page.dart';
import 'package:badminton_booking_app/pages/court/court_manager.dart';
import 'package:badminton_booking_app/pages/court/tabs/image_tab.dart';
import 'package:badminton_booking_app/pages/court/tabs/review_tab.dart';
import 'package:badminton_booking_app/pages/court/tabs/rule_tab.dart';
import 'package:badminton_booking_app/pages/court/tabs/service_tab.dart';
import 'package:badminton_booking_app/services/booking_service.dart';
import 'package:badminton_booking_app/services/court_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CourtDetail extends StatefulWidget {
  const CourtDetail({
    super.key,
    required this.court,
    this.courtService,
  });

  final Court court;
  final CourtService? courtService;

  @override
  State<CourtDetail> createState() => _CourtDetailState();
}

class _CourtDetailState extends State<CourtDetail>
    with TickerProviderStateMixin {
  bool _isFavorite = false;
  late CourtDetailData _detailData;
  bool _isLoading = false;
  String? _errorMessage;
  late final CourtService _courtService;
  late final BookingService _bookingService;
  bool _isAvailabilityLoading = false;
  String? _availabilityError;
  int? _availableCourtsNow;
  DateTime? _availabilitySnapshotAt;

  @override
  void initState() {
    super.initState();
    _detailData = CourtDetailData(court: widget.court);
    _courtService = widget.courtService ?? _resolveCourtService();
    _bookingService = BookingService();
    _loadDetail();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final manager = Provider.of<CourtManager>(context);
    if (manager == null) return;

    final updatedCourt = _findCourtById(manager);
    if (updatedCourt != null && !identical(updatedCourt, _detailData.court)) {
      setState(() {
        _detailData = _detailData.copyWith(court: updatedCourt);
      });
    }
  }

  void _toggleFavorite() => setState(() => _isFavorite = !_isFavorite);

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _courtService.getCourtDetail(widget.court.id);
      if (!mounted) return;
      setState(() {
        _detailData = data;
        _isLoading = false;
      });
      _refreshAvailability();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _describeError(
          error,
          fallback: 'Unable to load court information. Please try again.',
        );
        _isLoading = false;
      });
    }
  }

  CourtService _resolveCourtService() {
    try {
      final manager = Provider.of<CourtManager>(context, listen: false);
      return manager.courtService;
    } on ProviderNotFoundException {
      return CourtService();
    }
  }

  Court? _findCourtById(CourtManager manager) {
    for (final court in manager.courts) {
      if (court.id == widget.court.id) {
        return court;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final headerWidgets = <Widget>[
      _buildAppBar(context, cs),
      SliverToBoxAdapter(child: _infoCard(context, cs)),
    ];

    if (_errorMessage != null) {
      headerWidgets.add(
        SliverToBoxAdapter(child: _buildErrorBanner(context, cs)),
      );
    }

    headerWidgets.add(
      SliverPersistentHeader(
        pinned: true,
        delegate: _SliverTabBarDelegate(
          TabBar(
            labelColor: cs.primary,
            unselectedLabelColor: cs.onSurface,
            indicatorColor: cs.primary,
            isScrollable: true,
            padding: const EdgeInsets.only(left: 5),
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(text: 'Services'),
              Tab(text: 'Photos'),
              Tab(text: 'Terms & rules'),
              Tab(text: 'Reviews'),
            ],
          ),
        ),
      ),
    );

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => headerWidgets,
          body: TabBarView(
            children: [
              CourtServicesTab(
                pricing: _detailData.pricing,
                services: _detailData.services,
                isLoading: _isLoading,
                errorMessage: _errorMessage,
                onRetry: _loadDetail,
              ),
              CourtImageGallery(
                images: _detailData.images,
                isLoading: _isLoading,
                errorMessage: _errorMessage,
                onRetry: _loadDetail,
                emptyMessage: 'This court has no photos yet.',
              ),
              Rules(items: _buildDefaultRules()),
              ReviewTab(courtId: _detailData.court.id),
            ],
          ),
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, ColorScheme cs) {
    final coverUrl = _detailData.court.coverImageUrl;

    return SliverAppBar(
      pinned: true,
      floating: false,
      expandedHeight: MediaQuery.of(context).size.height * 0.28,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        _circleBtn(
          icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
          onTap: _toggleFavorite,
          cs: cs,
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: FilledButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookingPage(
                    detailData: _detailData,
                  ),
                ),
              );
            },
            child: const Text('Book now'),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: _buildHeaderImage(coverUrl),
      ),
    );
  }

  Widget _infoCard(BuildContext context, ColorScheme cs) {
    final court = _detailData.court;
    final textTheme = Theme.of(context).textTheme;
    final location =
        court.location.isNotEmpty ? court.location : 'Address updating';
    final code = court.code.isNotEmpty ? court.code : 'Updating';
    final description = court.description?.trim();
    final openingText = _buildOpeningHoursText(_detailData.openingHours);
    final activeUnits = _detailData.units
        .where((unit) => unit.label.trim().isNotEmpty && unit.isActive)
        .toList(growable: false);

    final avatarImage = court.coverImageUrl != null &&
            court.coverImageUrl!.isNotEmpty
        ? NetworkImage(court.coverImageUrl!)
        : const AssetImage('assets/images/badminton_logo.jpg') as ImageProvider;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Material(
        elevation: 5,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: cs.surface,
            border: Border.all(color: cs.outline, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundImage: avatarImage,
                  radius: 28,
                ),
                title: Text(
                  court.name.isNotEmpty ? court.name : 'Court name updating',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('Court code: $code'),
                    if (description != null && description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: textTheme.bodySmall,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const Divider(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.place, size: 20),
                  const SizedBox(width: 6),
                  Expanded(child: Text(location)),
                ],
              ),
              const SizedBox(height: 12),
              if (openingText != null) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.schedule, size: 20),
                    const SizedBox(width: 6),
                    Expanded(child: Text(openingText)),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  const Icon(Icons.sports_tennis, size: 20),
                  const SizedBox(width: 6),
                  Text(_formatCourtQuantity(court.courtQuantity)),
                ],
              ),
              const SizedBox(height: 12),
              _buildAvailabilityStatus(
                context,
                cs,
                activeUnits.length,
              ),
              if (_isLoading) ...[
                const SizedBox(height: 16),
                const LinearProgressIndicator(minHeight: 3),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refreshAvailability() async {
    final activeUnits = _detailData.units.where((unit) => unit.isActive).toList();

    setState(() {
      _isAvailabilityLoading = true;
      _availabilityError = null;
    });

    if (activeUnits.isEmpty) {
      setState(() {
        _isAvailabilityLoading = false;
        _availabilityError = 'No data on active courts yet.';
      });
      return;
    }

    try {
      final now = DateTime.now();
      final bookings = await _bookingService.listBookings(
        courtId: widget.court.id,
        date: now,
      );

      final nowUtc = now.toUtc();
      final blockingUnits = <String>{};
      for (final booking in bookings) {
        final overlapsNow =
            booking.startTime.isBefore(nowUtc) && booking.endTime.isAfter(nowUtc);
        final isBlockingStatus = booking.status == BookingStatus.confirmed ||
            booking.status == BookingStatus.awaitingPayment ||
            booking.isActiveLock;

        if (overlapsNow && isBlockingStatus) {
          blockingUnits.add(booking.courtUnitId);
        }
      }

      final totalActive = activeUnits.length;
      final available = (totalActive - blockingUnits.length).clamp(0, totalActive);

      if (!mounted) return;
      setState(() {
        _availableCourtsNow = available;
        _availabilitySnapshotAt = DateTime.now();
        _isAvailabilityLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _availabilityError = _describeAvailabilityError(error);
        _isAvailabilityLoading = false;
      });
    }
  }

  String _describeAvailabilityError(Object error) {
    if (error is BookingServiceException) {
      return error.message;
    }
    final message = error.toString();
    if (message.isNotEmpty) return message;
    return 'Unable to check court availability. Please try again.';
  }

  Widget _buildErrorBanner(BuildContext context, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Unable to load full court details.',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: cs.onErrorContainer),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? '',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: cs.onErrorContainer),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _loadDetail,
                style: FilledButton.styleFrom(
                  backgroundColor: cs.onErrorContainer,
                  foregroundColor: cs.errorContainer,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvailabilityStatus(
    BuildContext context,
    ColorScheme cs,
    int totalActive,
  ) {
    final textTheme = Theme.of(context).textTheme;

    if (_isAvailabilityLoading) {
      return _buildAvailabilityTile(
        cs: cs,
        icon: Icons.hourglass_top,
        iconColor: cs.primary,
        content: Text(
          'Checking open courts...',
          style: textTheme.bodyMedium,
        ),
        trailing: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_availabilityError != null) {
      return _buildAvailabilityTile(
        cs: cs,
        icon: Icons.error_outline,
        iconColor: cs.error,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Unable to check availability',
              style: textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              _availabilityError!,
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: _refreshAvailability,
                child: const Text('Retry'),
              ),
            ),
          ],
        ),
      );
    }

    if (totalActive == 0) {
      return _buildAvailabilityTile(
        cs: cs,
        icon: Icons.help_outline,
        iconColor: cs.secondary,
        content: Text(
          'No active court data to show availability.',
          style: textTheme.bodyMedium,
        ),
      );
    }

    final available = (_availableCourtsNow ?? totalActive).clamp(0, totalActive);
    final snapshot = _availabilitySnapshotAt?.toLocal();
    final timeLabel = snapshot != null
        ? 'Updated at ${TimeOfDay.fromDateTime(snapshot).format(context)}'
        : 'No update time yet';
    final hasOpenSlots = available > 0;

    final headline = hasOpenSlots
        ? 'There are $available/$totalActive courts open right now'
        : 'There are no courts available at this time';

    return _buildAvailabilityTile(
      cs: cs,
      icon: hasOpenSlots ? Icons.event_available : Icons.event_busy,
      iconColor: hasOpenSlots ? cs.primary : cs.error,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            headline,
            style:
                textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            hasOpenSlots
        ? 'You can pick an open court to book now.'
        : 'Please try another time or check back later.',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          Text(
            timeLabel,
            style:
                textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityTile({
    required ColorScheme cs,
    required IconData icon,
    required Color iconColor,
    required Widget content,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 10),
          Expanded(child: content),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing,
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderImage(String? coverUrl) {
    final placeholder = Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/court_cover.jpg'),
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
      ),
    );

    if (coverUrl == null || coverUrl.isEmpty) {
      return placeholder;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          coverUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
          errorBuilder: (context, error, stackTrace) => placeholder,
        ),
        Container(color: Colors.black.withOpacity(0.15)),
      ],
    );
  }

  String _describeError(Object error, {required String fallback}) {
    if (error is CourtServiceException) {
      return error.message;
    }

    final message = error.toString();
    if (message.startsWith('Exception:')) {
      final trimmed = message.substring('Exception:'.length).trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }

    if (message.isNotEmpty) {
      return message;
    }

    return fallback;
  }

  List<String> _buildDefaultRules() {
    return const [
      'Place a deposit for peak hours if required.',
      'Cancel at least 6 hours in advance to receive a full refund.',
      'Wear appropriate athletic shoes and keep the space clean.',
      'No smoking and limit alcoholic drinks in the court area.',
      'Follow staff instructions and take care of shared property.',
    ];
  }

  String? _buildOpeningHoursText(List<CourtOpeningHour> hours) {
    final ranges = <String>[];
    for (final hour in hours) {
      final range = _formatTimeRange(hour.openTime, hour.closeTime);
      if (range != null && range.isNotEmpty) {
        ranges.add(range);
      }
    }

    if (ranges.isEmpty) return null;
    return ranges.join('\n');
  }

  String? _formatTimeRange(String open, String close) {
    final cleanOpen = open.trim();
    final cleanClose = close.trim();

    if (cleanOpen.isEmpty && cleanClose.isEmpty) {
      return null;
    }

    if (cleanOpen.isEmpty) {
      return 'Until $cleanClose';
    }

    if (cleanClose.isEmpty) {
      return 'From $cleanOpen';
    }

    return '$cleanOpen - $cleanClose';
  }

  String _formatCourtQuantity(int quantity) {
    if (quantity > 0) {
      return '$quantity active courts';
    }
    return 'Updating court count';
  }

  Widget _circleBtn({
    required IconData icon,
    required VoidCallback onTap,
    required ColorScheme cs,
  }) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: cs.primary),
        ),
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surface,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _SliverTabBarDelegate oldDelegate) {
    return oldDelegate._tabBar != _tabBar;
  }
}
