import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/recruitment_applicant.dart';
import '../../../models/recruitment_post.dart';
import '../../../services/recruitment_service.dart';

class RecruitmentApplicantsPage extends StatefulWidget {
  const RecruitmentApplicantsPage({
    super.key,
    required this.post,
  });

  final RecruitmentPost post;

  @override
  State<RecruitmentApplicantsPage> createState() =>
      _RecruitmentApplicantsPageState();
}

class _RecruitmentApplicantsPageState
    extends State<RecruitmentApplicantsPage> {
  final RecruitmentService _service = RecruitmentService();

  late RecruitmentPost _post;
  List<RecruitmentApplicant> _applicants = const [];
  bool _isLoading = true;
  bool _isClosing = false;
  String? _error;
  final Set<String> _updatingApplicantIds = <String>{};

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final applicants = await _service.fetchApplicants(_post.id);
      final refreshedPost = await _service.getRecruitmentById(_post.id);
      if (!mounted) return;
      setState(() {
        _applicants = applicants;
        _post = refreshedPost;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleUpdateStatus(
    RecruitmentApplicant applicant,
    String status,
  ) async {
    if (_updatingApplicantIds.contains(applicant.id)) return;

    setState(() {
      _updatingApplicantIds.add(applicant.id);
    });

    try {
      final updatedPost = await _service.updateApplicantStatus(
        applicantId: applicant.id,
        status: status,
      );
      final updatedApplicants = await _service.fetchApplicants(_post.id);
      if (!mounted) return;
      setState(() {
        _post = updatedPost;
        _applicants = updatedApplicants;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _updatingApplicantIds.remove(applicant.id);
      });
    }
  }

  Future<void> _handleCloseRecruitment() async {
    if (!_post.isActive) return;

    DateTime? expiresAt;

    if (!_post.hasCourt) {
      final now = DateTime.now();
      final baseDate = now;
      final initialTime = TimeOfDay.fromDateTime(_post.eventTime ?? now);

      final picked = await showTimePicker(
        context: context,
        initialTime: initialTime,
        helpText: 'Chọn giờ đóng bài',
      );

      if (picked == null) {
        return;
      }

      expiresAt = DateTime(
        baseDate.year,
        baseDate.month,
        baseDate.day,
        picked.hour,
        picked.minute,
      );
    } else {
      expiresAt = _post.eventTime ?? DateTime.now();
    }

    setState(() {
      _isClosing = true;
    });

    try {
      final updatedPost = await _service.closeRecruitment(
        recruitmentId: _post.id,
        expiresAt: expiresAt,
      );
      final updatedApplicants = await _service.fetchApplicants(_post.id);
      if (!mounted) return;
      setState(() {
        _post = updatedPost;
        _applicants = updatedApplicants;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã đóng bài tuyển.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isClosing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canManage = _post.isOwner;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yêu cầu tham gia'),
        actions: [
          if (canManage && _post.isActive)
            TextButton.icon(
              onPressed: _isClosing ? null : _handleCloseRecruitment,
              icon: _isClosing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.lock_outline),
              label: const Text('Đóng bài'),
            ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: _buildBody(canManage),
        ),
      ),
    );
  }

  Widget _buildBody(bool canManage) {
    if (!canManage) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Bạn không có quyền quản lý bài tuyển này.'),
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_applicants.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Chưa có yêu cầu tham gia nào.'),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemBuilder: (context, index) {
        final applicant = _applicants[index];
        return _ApplicantTile(
          applicant: applicant,
          isUpdating: _updatingApplicantIds.contains(applicant.id),
          onAccept: () => _handleUpdateStatus(applicant, 'accepted'),
          onReject: () => _handleUpdateStatus(applicant, 'rejected'),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemCount: _applicants.length,
    );
  }
}

class _ApplicantTile extends StatelessWidget {
  const _ApplicantTile({
    required this.applicant,
    required this.isUpdating,
    required this.onAccept,
    required this.onReject,
  });

  final RecruitmentApplicant applicant;
  final bool isUpdating;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  Color _statusColor(BuildContext context) {
    switch (applicant.status) {
      case 'accepted':
        return Theme.of(context).colorScheme.primaryContainer;
      case 'rejected':
        return Theme.of(context).colorScheme.errorContainer;
      default:
        return Theme.of(context).colorScheme.surfaceVariant;
    }
  }

  Color _statusTextColor(BuildContext context) {
    switch (applicant.status) {
      case 'accepted':
        return Theme.of(context).colorScheme.primary;
      case 'rejected':
        return Theme.of(context).colorScheme.error;
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  String _statusLabel() {
    switch (applicant.status) {
      case 'accepted':
        return 'Đã duyệt';
      case 'rejected':
        return 'Đã từ chối';
      default:
        return 'Chờ duyệt';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final playStyles = applicant.playStyles.join(', ');

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: cs.primary,
                  backgroundImage: applicant.avatarUrl != null
                      ? NetworkImage(applicant.avatarUrl!)
                      : null,
                  child: applicant.avatarUrl == null
                      ? Text(
                          applicant.displayName.isNotEmpty
                              ? applicant.displayName[0].toUpperCase()
                              : '?',
                          style: textTheme.titleMedium?.copyWith(
                            color: cs.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        applicant.displayName,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _statusColor(context),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _statusLabel(),
                              style: textTheme.labelMedium?.copyWith(
                                color: _statusTextColor(context),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('dd/MM HH:mm').format(applicant.createdAt),
                            style: textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (applicant.level != null && applicant.level!.isNotEmpty) ...[
              Text(
                'Trình độ: ${applicant.level}',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
            ],
            if (playStyles.isNotEmpty) ...[
              Text(
                'Lối đánh: $playStyles',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: _buildActions(context),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    if (applicant.status != 'pending') {
      return [
        Text(
          applicant.status == 'accepted' ? 'Đã chấp nhận' : 'Đã từ chối',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ];
    }

    return [
      TextButton.icon(
        onPressed: isUpdating ? null : onReject,
        icon: const Icon(Icons.close, color: Colors.red),
        label: const Text('Từ chối'),
      ),
      const SizedBox(width: 8),
      FilledButton.icon(
        onPressed: isUpdating ? null : onAccept,
        icon: isUpdating
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.check_circle_outline),
        label: const Text('Chấp nhận'),
      ),
    ];
  }
}
