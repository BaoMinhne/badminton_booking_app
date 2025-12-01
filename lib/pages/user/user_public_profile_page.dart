import 'package:badminton_booking_app/models/friend_search_result.dart';
import 'package:badminton_booking_app/models/user_details.dart';
import 'package:badminton_booking_app/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserPublicProfilePage extends StatefulWidget {
  const UserPublicProfilePage({super.key, required this.result});

  final FriendSearchResult result;

  @override
  State<UserPublicProfilePage> createState() => _UserPublicProfilePageState();
}

class _UserPublicProfilePageState extends State<UserPublicProfilePage> {
  static const Map<int, String> _levelLabels = {
    1: 'Beginner',
    2: 'Lower Intermediate',
    3: 'Intermediate',
    4: 'Upper Intermediate',
    5: 'Advanced',
  };

  late final UserDetailsService _service;
  UserDetails? _details;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = UserDetailsService();
    _details = widget.result.details;
    _isLoading = _details == null;
    if (_details == null) {
      _fetchDetails();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _fetchDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final details = await _service.getByUserId(widget.result.user.id);
      if (!mounted) return;
      setState(() {
        _details = details;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Không thể tải hồ sơ người dùng. Vui lòng thử lại sau.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchDetails,
          child: CustomScrollView(
            slivers: [
              _buildAppBar(context),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _buildBodyContent(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final details = _details;
    final name = (details?.fullname?.trim().isNotEmpty ?? false)
        ? details!.fullname!.trim()
        : widget.result.displayName;

    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: cs.surface,
      foregroundColor: cs.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            _buildCover(cs),
            Positioned(
              left: 20,
              right: 20,
              bottom: 28,
              child: _buildHeaderCard(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCover(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primary.withOpacity(0.9),
            cs.primaryContainer,
            cs.surfaceVariant,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -20,
            child: _blurCircle(cs.primary.withOpacity(0.3), 150),
          ),
          Positioned(
            bottom: -30,
            left: -10,
            child: _blurCircle(cs.secondary.withOpacity(0.35), 140),
          ),
        ],
      ),
    );
  }

  Widget _blurCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 60,
            spreadRadius: 30,
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final details = _details;

    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(24),
      shadowColor: Colors.black.withOpacity(0.15),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: cs.surface,
        ),
        child: Row(
          children: [
            _buildAvatar(cs),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    (details?.fullname?.trim().isNotEmpty ?? false)
                        ? details!.fullname!.trim()
                        : widget.result.displayName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildLevelChip(cs),
                      const SizedBox(width: 8),
                      _buildIntensityChip(cs),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.email_outlined,
                          size: 18, color: cs.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.result.user.email.isNotEmpty
                              ? widget.result.user.email
                              : widget.result.user.phone,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(ColorScheme cs) {
    final avatarUrl = _details?.avatarUrl;
    final initials = widget.result.initials;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cs.surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 42,
        backgroundColor: cs.primaryContainer,
        foregroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
            ? NetworkImage(avatarUrl)
            : null,
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildLevelChip(ColorScheme cs) {
    final level = _details?.level?.trim();
    final numeric = _details?.levelNumeric;
    final label = (level != null && level.isNotEmpty)
        ? level
        : _levelLabels[numeric ?? 3] ?? 'Level 3';

    return Chip(
      label: Text(label),
      avatar: const Icon(Icons.emoji_events_rounded, size: 18),
      backgroundColor: cs.primaryContainer,
      labelStyle: TextStyle(
        color: cs.onPrimaryContainer,
        fontWeight: FontWeight.w600,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6),
    );
  }

  Widget _buildIntensityChip(ColorScheme cs) {
    final intensity = _details?.intensity;
    if (intensity == null || intensity.isEmpty) {
      return Chip(
        label: const Text('Chưa cập nhật'),
        backgroundColor: cs.surfaceVariant,
        labelStyle: TextStyle(color: cs.onSurfaceVariant),
      );
    }

    return Chip(
      label: Text(_humanize(intensity)),
      avatar: const Icon(Icons.local_fire_department_outlined, size: 18),
      backgroundColor: cs.secondaryContainer,
      labelStyle: TextStyle(
        color: cs.onSecondaryContainer,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildBodyContent(BuildContext context) {
    if (_isLoading) {
      return const Center(
        key: ValueKey('loading'),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Center(
        key: const ValueKey('error'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 40, color: Colors.red),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: _fetchDetails, child: const Text('Thử lại')),
          ],
        ),
      );
    }

    final details = _details;
    if (details == null) {
      return const SizedBox.shrink();
    }

    return Column(
      key: const ValueKey('content'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildActionRow(context),
        const SizedBox(height: 18),
        _buildHighlightCards(context),
        const SizedBox(height: 16),
        _buildInfoSection(
          context,
          title: 'Thông tin cơ bản',
          items: [
            _infoTile(Icons.person_outline, 'Giới tính',
                _humanize(details.gender) ?? 'Chưa cập nhật'),
            _infoTile(
              Icons.cake_outlined,
              'Ngày sinh',
              _formatBirthday(details.birthday),
            ),
            _infoTile(
              Icons.house_outlined,
              'Sân yêu thích',
              details.homeCourtId ?? 'Chưa cập nhật',
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoSection(
          context,
          title: 'Lối chơi & sở thích',
          items: [
            _chipsTile(
              context,
              icon: Icons.sports_tennis_outlined,
              label: 'Hình thức thi đấu',
              values: details.matchTypes,
            ),
            _chipsTile(
              context,
              icon: Icons.style_outlined,
              label: 'Phong cách',
              values: details.playStyleTags,
            ),
            _infoTile(
              Icons.people_outline,
              'Vị trí ưa thích khi đánh đôi',
              _humanize(details.preferredRoleDoubles) ?? 'Chưa cập nhật',
            ),
            _infoTile(
              Icons.local_fire_department_outlined,
              'Mức độ nghiêm túc',
              _humanize(details.intensity) ?? 'Chưa cập nhật',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionRow(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.send_rounded),
              label: const Text('Nhắn tin'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.tonalIcon(
              onPressed: () {},
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Kết bạn'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightCards(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final details = _details;

    return Row(
      children: [
        Expanded(
          child: _statCard(
            context,
            icon: Icons.stacked_line_chart_rounded,
            label: 'Trình độ',
            value: _levelLabels[details?.levelNumeric ?? 3] ?? 'Intermediate',
            background: cs.primaryContainer,
            foreground: cs.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            context,
            icon: Icons.calendar_month_outlined,
            label: 'Số buổi/tuần',
            value: details?.playsPerWeek?.toString() ?? 'Chưa rõ',
            background: cs.secondaryContainer,
            foreground: cs.onSecondaryContainer,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            context,
            icon: Icons.military_tech_outlined,
            label: 'Kinh nghiệm',
            value: details?.experienceYears != null
                ? '${details!.experienceYears} năm'
                : 'Chưa rõ',
            background: cs.tertiaryContainer,
            foreground: cs.onTertiaryContainer,
          ),
        ),
      ],
    );
  }

  Widget _statCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color background,
    required Color foreground,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: background,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foreground),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context,
      {required String title, required List<Widget> items}) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...items,
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    final formatted = value.isEmpty ? 'Chưa cập nhật' : value;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  formatted,
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipsTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required List<String> values,
  }) {
    final cs = Theme.of(context).colorScheme;
    final chips = values
        .where((e) => e.trim().isNotEmpty)
        .map(
          (value) => Chip(
            label: Text(_humanize(value)),
            backgroundColor: cs.surfaceVariant,
            labelStyle: TextStyle(color: cs.onSurfaceVariant),
          ),
        )
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                if (chips.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: chips,
                  )
                else
                  Text(
                    'Chưa cập nhật',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatBirthday(DateTime? birthday) {
    if (birthday == null) return 'Chưa cập nhật';
    return DateFormat('dd/MM/yyyy').format(birthday);
  }

  String? _humanize(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return raw
        .split('_')
        .map((word) =>
            word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}
