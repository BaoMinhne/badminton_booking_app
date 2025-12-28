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

class _RecruitmentApplicantsPageState extends State<RecruitmentApplicantsPage> {
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
    DateTime? expiresAt;

    if (!_post.hasCourt) {
      final now = DateTime.now();
      final baseDate = now;
      final initialTime = TimeOfDay.fromDateTime(_post.eventTime ?? now);

      final picked = await showTimePicker(
        context: context,
        initialTime: initialTime,
        helpText: 'Select closing time',
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
        const SnackBar(content: Text('Recruitment post closed.')),
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
    final canClose = canManage;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join requests'),
        actions: [
          if (canManage)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TextButton.icon(
                onPressed: canClose && !_isClosing ? _handleCloseRecruitment : null,
                icon: _isClosing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(canClose ? Icons.lock_outline : Icons.lock),
                label: Text(canClose ? 'Close post' : 'Closed'),
              ),
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
          child: Text('You do not have permission to manage this recruitment.'),
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
                child: const Text('Try again'),
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
          child: Text('No join requests yet.'),
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
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final playStyles = applicant.playStyles.join(', ');

    // Vibrant status colors
    final Color statusBgColor;
    final Color statusTextColor;
    final IconData? statusIcon;

    switch (applicant.status) {
      case 'pending':
        statusBgColor = Colors.orange.shade100;
        statusTextColor = Colors.orange.shade800;
        statusIcon = Icons.access_time_filled;
        break;
      case 'accepted':
        statusBgColor = Colors.green.shade100;
        statusTextColor = Colors.green.shade800;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusBgColor = Colors.red.shade50;
        statusTextColor = Colors.red.shade700;
        statusIcon = Icons.cancel;
        break;
      default:
        statusBgColor = cs.primary.withOpacity(0.1);
        statusTextColor = cs.primary;
        statusIcon = null;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: applicant.status == 'rejected'
              ? Colors.red.shade200.withOpacity(0.6)
              : cs.outline.withOpacity(0.45),
          width: applicant.status == 'rejected'
              ? 1.8
              : 1.4, // Slightly thicker border when rejected
        ),
        boxShadow: [
          BoxShadow(
            color: applicant.status == 'rejected'
                ? Colors.red.shade100.withOpacity(0.3)
                : cs.shadow.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Avatar + Info
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: cs.primary.withOpacity(0.15),
                  backgroundImage: applicant.avatarUrl != null
                      ? NetworkImage(applicant.avatarUrl!)
                      : null,
                  child: applicant.avatarUrl == null
                      ? Text(
                          applicant.displayName.isNotEmpty
                              ? applicant.displayName[0].toUpperCase()
                              : '?',
                          style: textTheme.titleLarge?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        applicant.displayName,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Status label with bold text and icon
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: statusBgColor,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                  color: statusTextColor.withOpacity(0.4),
                                  width: 1.2),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon,
                                    size: 16, color: statusTextColor),
                                const SizedBox(width: 6),
                                Text(
                                  _statusLabel(),
                                  style: textTheme.labelMedium?.copyWith(
                                    color: statusTextColor,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat('dd/MM HH:mm')
                                .format(applicant.createdAt),
                            style: textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant.withOpacity(0.85),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Player details – skill level & play style
            if (applicant.level != null && applicant.level!.isNotEmpty)
              _infoRow(
                icon: Icons.trending_up_rounded,
                color: Colors.deepPurple.shade600,
                label: 'Skill level',
                value: applicant.level!,
                textTheme: textTheme,
              ),

            if (applicant.level != null && applicant.level!.isNotEmpty)
              const SizedBox(height: 10),

            if (playStyles.isNotEmpty)
              _infoRow(
                icon: Icons.sports_tennis_rounded,
                color: Colors.teal.shade600,
                label: 'Play style',
                value: playStyles,
                textTheme: textTheme,
              ),

            const SizedBox(height: 20),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: _buildActions(context).map((widget) {
                if (widget is TextButton) {
                  final text = widget.child is Text
                      ? (widget.child as Text).data ?? ''
                      : '';

                  if (text.contains('Accept') || text.contains('Agree')) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: FilledButton.icon(
                        onPressed: widget.onPressed,
                        icon: const Icon(Icons.check_circle_rounded, size: 20),
                        label: Text(text,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 22, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                          elevation: 2,
                        ),
                      ),
                    );
                  }

                  if (text.contains('Reject') || text.contains('Cancel')) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: OutlinedButton.icon(
                        onPressed: widget.onPressed,
                        icon: const Icon(Icons.cancel_rounded, size: 20),
                        label: Text(text,
                            style: TextStyle(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          side:
                              BorderSide(color: Colors.red.shade400, width: 2),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 22, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                        ),
                      ),
                    );
                  }
                }
                return Padding(
                    padding: const EdgeInsets.only(left: 10), child: widget);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

// Helper: Info row with balanced colors
  Widget _infoRow({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    required TextTheme textTheme,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    if (applicant.status != 'pending') {
      return [
        Text(
          applicant.status == 'accepted' ? 'Accepted' : 'Rejected',
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
        label: const Text('Reject'),
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
        label: const Text('Accept'),
      ),
    ];
  }
}
