import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/court.dart';
import '../../../models/friend_search_result.dart';
import '../../../models/invitation.dart';
import '../../../models/recruitment_post.dart';
import '../../../models/user_booking_view.dart';
import '../../../services/invitation_service.dart';
import 'invitation_manager.dart';

class InvitationSheet extends StatefulWidget {
  const InvitationSheet({super.key, required this.toUser, required this.manager});

  final FriendSearchResult toUser;
  final InvitationManager manager;

  @override
  State<InvitationSheet> createState() => _InvitationSheetState();
}

class _InvitationSheetState extends State<InvitationSheet> {
  InvitationComposerData? _data;
  bool _isLoading = false;
  String? _error;

  String? _selectedRecruitment;
  UserBookingView? _selectedBooking;
  String? _selectedCourt;
  DateTime _proposedStart = DateTime.now().add(const Duration(hours: 1));
  DateTime? _proposedEnd;
  String? _note;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await widget.manager.loadComposerData();
      setState(() {
        _data = data;

        if (data.recruitments.length == 1) {
          _selectedRecruitment = data.recruitments.first.id;
        } else if (data.recruitments.isEmpty && data.bookings.length == 1) {
          _selectedBooking = data.bookings.first;
        }

        _selectedCourt = data.courts.isNotEmpty ? data.courts.first.id : null;
      });
    } catch (err) {
      setState(() {
        _error = err.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 16,
        left: 20,
        right: 20,
      ),
      child: _isLoading
          ? const SizedBox(
              height: 240,
              child: Center(child: CircularProgressIndicator()),
            )
          : _error != null
              ? _ErrorState(message: _error!, onRetry: _loadData)
              : _buildContent(context, cs),
    );
  }

  Widget _buildContent(BuildContext context, ColorScheme cs) {
    final data = _data!;
    final recruitments = data.recruitments;
    final bookings = data.bookings;
    final courts = data.courts;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.handshake_rounded, color: cs.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Mời ${widget.toUser.displayName} vào slot',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          if (recruitments.isNotEmpty) ...[
            Text('Bài tuyển đang mở', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...recruitments.map(
              (post) => RadioListTile<String>(
                value: post.id,
                groupValue: _selectedRecruitment,
                onChanged: (value) {
                  setState(() {
                    _selectedRecruitment = value;
                    _selectedBooking = null;
                  });
                },
                title: Text(post.courtName ?? 'Chưa chọn sân'),
                subtitle: Text(
                  _formatSlot(post.eventTime, null) ?? 'Bài tuyển chưa chọn giờ',
                ),
              ),
            ),
            const Divider(),
          ],
          if (bookings.isNotEmpty) ...[
            Text('Booking hiện có', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...bookings.map(
              (booking) => RadioListTile<UserBookingView>(
                value: booking,
                groupValue: _selectedBooking,
                onChanged: (value) {
                  setState(() {
                    _selectedBooking = value;
                    _selectedRecruitment = null;
                  });
                },
                title: Text(booking.courtName ?? 'Sân chưa rõ'),
                subtitle: Text(_formatSlot(booking.startTime, booking.endTime) ?? ''),
              ),
            ),
            const Divider(),
          ],
          if (_selectedRecruitment == null) ...[
            Text('Đề xuất slot mới', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCourt,
              items: courts
                  .map(
                    (court) => DropdownMenuItem(
                      value: court.id,
                      child: Text(court.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedCourt = value),
              decoration: const InputDecoration(labelText: 'Chọn sân'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: 'Bắt đầu',
                    value: _proposedStart,
                    onChanged: (value) => setState(() => _proposedStart = value),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateField(
                    label: 'Kết thúc (tuỳ chọn)',
                    value:
                        _proposedEnd ?? _proposedStart.add(const Duration(hours: 2)),
                    onChanged: (value) => setState(() => _proposedEnd = value),
                    optional: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            decoration: const InputDecoration(labelText: 'Ghi chú gửi kèm'),
            onChanged: (value) => _note = value,
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _handleSubmit,
            icon: const Icon(Icons.send_rounded),
            label: const Text('Gửi lời mời'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (_data == null) return;
    final toUserId = widget.toUser.user.id;

    try {
      if (_selectedRecruitment != null) {
        final recruitmentId = _selectedRecruitment!;
        await widget.manager.sendRecruitmentInvite(
          toUserId: toUserId,
          recruitmentId: recruitmentId,
          message: _note,
        );
      } else if (_selectedBooking != null || _data!.bookings.isNotEmpty) {
        final booking = _selectedBooking ?? _data!.bookings.first;
        await widget.manager.sendBookingInvite(
          toUserId: toUserId,
          booking: booking,
          message: _note,
        );
      } else {
        await widget.manager.sendProposedInvite(
          toUserId: toUserId,
          startTime: _proposedStart,
          endTime: _proposedEnd,
          courtId: _selectedCourt,
          message: _note,
        );
      }

      if (mounted) Navigator.of(context).pop();
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err.toString())),
      );
    }
  }

  String? _formatSlot(DateTime? start, DateTime? end) {
    if (start == null) return null;
    final formatter = DateFormat('HH:mm dd/MM');
    if (end == null) return formatter.format(start);
    return '${formatter.format(start)} - ${formatter.format(end)}';
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.optional = false,
  });

  final String label;
  final DateTime value;
  final bool optional;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(
      text: DateFormat('HH:mm dd/MM').format(value),
    );

    return TextField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(labelText: label),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime.now().subtract(const Duration(days: 1)),
          lastDate: DateTime.now().add(const Duration(days: 60)),
        );
        if (date == null) return;
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(value),
        );
        final result = DateTime(
          date.year,
          date.month,
          date.day,
          time?.hour ?? value.hour,
          time?.minute ?? value.minute,
        );
        onChanged(result);
      },
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}
