import 'package:badminton_booking_app/models/court.dart';
import 'package:badminton_booking_app/models/court_detail.dart';
import 'package:badminton_booking_app/pages/court/tabs/image_tab.dart';
import 'package:badminton_booking_app/pages/court/tabs/review_tab.dart';
import 'package:badminton_booking_app/pages/court/tabs/rule_tab.dart';
import 'package:badminton_booking_app/pages/court/tabs/service_tab.dart';
import 'package:badminton_booking_app/services/court_service.dart';
import 'package:flutter/material.dart';

class CourtDetail extends StatefulWidget {
  final String courtId;
  final Court? initialCourt;

  const CourtDetail({
    super.key,
    required this.courtId,
    this.initialCourt,
  });

  @override
  State<CourtDetail> createState() => _CourtDetailState();
}

class _CourtDetailState extends State<CourtDetail> {
  final CourtService _courtService = CourtService();

  bool _isFavorite = false;
  bool _isLoading = true;
  String? _errorMessage;
  Court? _court;
  List<String> _images = const [];
  List<CourtOpeningHour> _openingHours = const [];
  List<CourtPricing> _pricing = const [];
  List<CourtUnit> _units = const [];

  @override
  void initState() {
    super.initState();
    _court = widget.initialCourt;
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final details = await _courtService.getCourtDetails(widget.courtId);
      if (!mounted) return;
      setState(() {
        _court = details.court;
        _images = details.images;
        _openingHours = details.openingHours;
        _pricing = details.pricing;
        _units = details.units;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final message = e.toString();
      setState(() {
        _errorMessage = message.startsWith('Exception: ')
            ? message.replaceFirst('Exception: ', '')
            : message;
        _isLoading = false;
      });
    }
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    if (_court == null && _isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_court == null) {
      return _buildErrorView(cs);
    }

    final court = _court!;
    final heroImage = _images.isNotEmpty
        ? _images.first
        : (court.coverImageUrl != null && court.coverImageUrl!.isNotEmpty
            ? court.coverImageUrl!
            : null);

    return Scaffold(
      body: Stack(
        children: [
          _buildHeroBackground(context, screenWidth, heroImage),
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _circleBtn(
                  icon: Icons.arrow_back,
                  onTap: () => Navigator.pop(context),
                  cs: cs,
                ),
                Row(
                  children: [
                    _circleBtn(
                      icon:
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                      onTap: _toggleFavorite,
                      cs: cs,
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade400,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text('Đặt lịch'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.only(left: 20, top: 40, right: 20, bottom: 40),
            margin: EdgeInsets.only(
              top: MediaQuery.of(context).size.height / 4,
            ),
            height: MediaQuery.of(context).size.height,
            width: screenWidth,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: screenWidth / 4.5),
            child: _infoTab(cs, court),
          ),
          Container(
            padding: EdgeInsets.only(
              top: screenWidth - 65,
            ),
            child: DefaultTabController(
              length: 4,
              child: Column(
                children: [
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
                  Expanded(
                    child: TabBarView(
                      children: [
                        PricingTableMini(
                          items: _buildServicePrices(),
                          units: _units
                              .where((unit) => unit.isActive)
                              .map((unit) => unit.label)
                              .where((label) => label.isNotEmpty)
                              .toList(growable: false),
                        ),
                        CourtImageGallery(images: _images),
                        Rules(items: const [
                          'Đặt cọc 50% cho giờ cao điểm',
                          'Hủy trước 6h hoàn 100%, sau đó không hoàn',
                          'Đi giày cầu lông, không hút thuốc trong sân',
                          'Giữ vệ sinh chung, không xả rác bừa bãi',
                          'Tuân thủ quy định của sân và nhân viên sân',
                          'Không mang đồ ăn thức uống có cồn vào sân',
                          'Giữ gìn tài sản cá nhân, sân không chịu trách nhiệm',
                        ]),
                        const ReviewTab(initialReviews: []),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_errorMessage != null && !_isLoading && _court != null)
            _buildWarningBanner(cs),
          if (_isLoading)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: Container(
                  color: Colors.black.withOpacity(0.05),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeroBackground(
    BuildContext context,
    double screenWidth,
    String? heroImage,
  ) {
    ImageProvider imageProvider;
    if (heroImage != null && heroImage.isNotEmpty) {
      imageProvider = heroImage.startsWith('http')
          ? NetworkImage(heroImage)
          : AssetImage(heroImage) as ImageProvider;
    } else {
      imageProvider =
          const AssetImage('assets/images/court_cover.jpg') as ImageProvider;
    }

    return Container(
      height: MediaQuery.of(context).size.height / 2,
      width: screenWidth,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: imageProvider,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
      ),
    );
  }

  Widget _infoTab(ColorScheme cs, Court court) {
    final location = court.location.isNotEmpty
        ? court.location
        : 'Chưa cập nhật vị trí';
    final openingHoursText = _openingHours.isEmpty
        ? 'Chưa cập nhật'
        : _openingHours
            .map((hour) => '${hour.openTime} - ${hour.closeTime}')
            .join('\n');

    final chips = <Widget>[];
    if (court.code.isNotEmpty) {
      chips.add(_buildInfoChip(cs, 'Mã: ${court.code}'));
    }
    chips.add(_buildInfoChip(cs, '${court.courtQuantity} sân'));
    chips.add(_buildInfoChip(
      cs,
      court.isActive ? 'Đang hoạt động' : 'Tạm ngưng',
      highlight: court.isActive,
    ));

    return SingleChildScrollView(
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
                  backgroundImage: court.coverImageUrl != null &&
                          court.coverImageUrl!.isNotEmpty
                      ? NetworkImage(court.coverImageUrl!)
                      : const AssetImage('assets/images/badminton_logo.jpg')
                          as ImageProvider,
                  radius: 28,
                ),
                title: Text(
                  court.name.isNotEmpty
                      ? court.name
                      : 'Sân chưa đặt tên',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: chips,
                    ),
                    if (court.description != null &&
                        court.description!.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        court.description!,
                        style: TextStyle(
                          color: cs.onSurface.withOpacity(0.75),
                        ),
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.schedule, size: 20),
                  const SizedBox(width: 6),
                  Expanded(child: Text(openingHoursText)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.call, size: 20),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Liên hệ quản lý sân để biết thêm thông tin.',
                      style: TextStyle(
                        color: cs.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
              if (_units.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Các sân hiện có',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _units
                      .map((unit) => _buildUnitChip(cs, unit))
                      .toList(growable: false),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<ServicePrice> _buildServicePrices() {
    if (_pricing.isEmpty) return const [];

    return _pricing
        .map(
          (pricing) => ServicePrice(
            name: _buildPricingName(pricing),
            unit: 'giờ',
            price: pricing.pricePerHour,
            note: pricing.priceLabel,
          ),
        )
        .toList(growable: false);
  }

  String _buildPricingName(CourtPricing pricing) {
    final from = pricing.timeFrom;
    final to = pricing.timeTo;
    if (from != null && from.isNotEmpty && to != null && to.isNotEmpty) {
      return 'Khung giờ $from - $to';
    }
    if (from != null && from.isNotEmpty) {
      return 'Từ $from';
    }
    if (to != null && to.isNotEmpty) {
      return 'Đến $to';
    }
    return 'Giá thuê theo giờ';
  }

  Widget _buildInfoChip(ColorScheme cs, String label, {bool highlight = true}) {
    final backgroundColor = highlight
        ? cs.primary.withOpacity(0.12)
        : cs.onSurface.withOpacity(0.08);
    final borderColor = highlight
        ? cs.primary.withOpacity(0.2)
        : cs.onSurface.withOpacity(0.12);
    final textColor = highlight
        ? cs.primary
        : cs.onSurface.withOpacity(0.75);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildUnitChip(ColorScheme cs, CourtUnit unit) {
    final active = unit.isActive;
    return Chip(
      avatar: Icon(
        active ? Icons.check_circle : Icons.cancel,
        size: 16,
        color: active ? cs.primary : cs.onSurface.withOpacity(0.6),
      ),
      label: Text(unit.label),
      backgroundColor:
          active ? cs.primary.withOpacity(0.12) : cs.onSurface.withOpacity(0.08),
      labelStyle: TextStyle(
        color: active ? cs.primary : cs.onSurface.withOpacity(0.75),
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildWarningBanner(ColorScheme cs) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 72,
      left: 16,
      right: 16,
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        color: cs.errorContainer.withOpacity(0.9),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: cs.onErrorContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _errorMessage ?? '',
                  style: TextStyle(color: cs.onErrorContainer),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: cs.onErrorContainer),
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView(ColorScheme cs) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin sân'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                'Không thể tải thông tin sân',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadDetails,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
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
          child: Icon(
            icon,
            color: cs.primary,
          ),
        ),
      ),
    );
  }
}
