import 'package:badminton_booking_app/components/my_court.dart';
import 'package:badminton_booking_app/models/court.dart';
import 'package:badminton_booking_app/pages/court/court_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CourtPage extends StatelessWidget {
  CourtPage({super.key});

  @override
  Widget build(BuildContext context) {
    final courtManager = context.watch<CourtManager>();

    Widget body;

    if (courtManager.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (courtManager.errorMessage != null) {
      body = _buildErrorState(context, courtManager.errorMessage!);
    } else if (courtManager.courts.isEmpty) {
      body = _buildEmptyState(context);
    } else {
      body = _buildContent(context, courtManager.courts);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'C O U R T',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        centerTitle: true,
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: body,
    );
  }

  Widget _buildContent(BuildContext context, List<Court> courts) {
    final recommended = courts.take(5).toList();
    final remainingAfterRecommended = courts.skip(recommended.length).toList();
    final nearby = remainingAfterRecommended.take(5).toList();
    final popular = remainingAfterRecommended.skip(nearby.length).toList();

    final sections = <Widget>[
      const SizedBox(height: 10),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sections,
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
