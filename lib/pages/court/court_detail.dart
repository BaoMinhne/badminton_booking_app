import 'package:badminton_booking_app/models/court.dart';
import 'package:badminton_booking_app/models/court_detail.dart';
import 'package:badminton_booking_app/pages/court/booking_page.dart';
import 'package:badminton_booking_app/pages/court/court_manager.dart';
import 'package:badminton_booking_app/pages/court/tabs/image_tab.dart';
import 'package:badminton_booking_app/pages/court/tabs/review_tab.dart';
import 'package:badminton_booking_app/pages/court/tabs/rule_tab.dart';
import 'package:badminton_booking_app/pages/court/tabs/service_tab.dart';
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

  @override
  void initState() {
    super.initState();
    _detailData = CourtDetailData(court: widget.court);
    _courtService = widget.courtService ?? _resolveCourtService();
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
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _describeError(
          error,
          fallback: 'Không thể tải thông tin sân. Vui lòng thử lại.',
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
              Tab(text: 'Dịch vụ'),
              Tab(text: 'Hình ảnh'),
              Tab(text: 'Điều khoản & quy định'),
              Tab(text: 'Đánh giá'),
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
                emptyMessage: 'Sân chưa có hình ảnh.',
              ),
              Rules(items: _buildDefaultRules()),
              const ReviewTab(initialReviews: []),
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
                    court: _detailData.court,
                  ),
                ),
              );
            },
            child: const Text('Đặt lịch'),
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
        court.location.isNotEmpty ? court.location : 'Địa chỉ đang cập nhật';
    final code = court.code.isNotEmpty ? court.code : 'Đang cập nhật';
    final description = court.description?.trim();
    final openingText = _buildOpeningHoursText(_detailData.openingHours);
    final unitLabels = _detailData.units
        .where((unit) => unit.label.trim().isNotEmpty && unit.isActive)
        .map((unit) => unit.label.trim())
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
                  court.name.isNotEmpty ? court.name : 'Tên sân đang cập nhật',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('Mã sân: $code'),
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
              if (unitLabels.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: unitLabels
                      .map(
                        (label) => Chip(
                          label: Text(label),
                          backgroundColor: cs.primary.withOpacity(0.1),
                          side: BorderSide(color: cs.primary.withOpacity(0.4)),
                          labelStyle: TextStyle(color: cs.primary),
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
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
                'Không thể tải đầy đủ thông tin sân.',
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
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
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
      'Đặt cọc trước với khung giờ cao điểm nếu được yêu cầu.',
      'Hủy lịch trước 6 giờ để được hoàn cọc đầy đủ.',
      'Mang giày thể thao phù hợp và giữ vệ sinh chung.',
      'Không hút thuốc và hạn chế đồ uống có cồn trong khu vực sân.',
      'Tuân thủ hướng dẫn của nhân viên và bảo vệ tài sản chung.',
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
      return 'Đến $cleanClose';
    }

    if (cleanClose.isEmpty) {
      return 'Từ $cleanOpen';
    }

    return '$cleanOpen - $cleanClose';
  }

  String _formatCourtQuantity(int quantity) {
    if (quantity > 0) {
      return '$quantity sân hoạt động';
    }
    return 'Đang cập nhật số lượng sân';
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
