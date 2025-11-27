import 'package:badminton_booking_app/pages/social/recruitment/recruitment_form_manager.dart';
import 'package:badminton_booking_app/pages/social/recruitment/widgets/court_info_section.dart';
import 'package:badminton_booking_app/pages/social/recruitment/widgets/intro_card.dart';
import 'package:badminton_booking_app/pages/social/recruitment/widgets/member_input_section.dart';
import 'package:badminton_booking_app/pages/social/recruitment/widgets/no_court_info_box.dart';
import 'package:badminton_booking_app/pages/social/recruitment/widgets/note_field.dart';
import 'package:badminton_booking_app/pages/social/recruitment/widgets/play_style_selector.dart';
import 'package:badminton_booking_app/pages/social/recruitment/widgets/skill_level_selector.dart';
import 'package:badminton_booking_app/pages/social/recruitment/widgets/submit_button.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class RecruitmentFormPage extends StatelessWidget {
  const RecruitmentFormPage({super.key});

  Future<void> _pickDateTime(BuildContext context) async {
    final manager = context.read<RecruitmentFormManager>();
    final initialDate = manager.selectedDateTime;
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (time == null) return;

    final newDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    await manager.updateSelectedDateTime(newDateTime);
  }

  Future<void> _pickCloseDateTime(BuildContext context) async {
    final manager = context.read<RecruitmentFormManager>();
    final initialDate = manager.expiresAt;
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );

    if (time == null) return;

    final newDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    manager.updateExpiresAt(newDateTime);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RecruitmentFormManager()..initialize(),
      child: Builder(
        builder: (context) {
          final manager = context.watch<RecruitmentFormManager>();
          final cs = Theme.of(context).colorScheme;
          final textTheme = Theme.of(context).textTheme;

          return Scaffold(
            appBar: AppBar(title: const Text('Tạo bài tuyển thành viên')),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IntroCard(cs: cs, textTheme: textTheme),
                    const SizedBox(height: 24),

                    _DateTimeField(
                      label: 'Giờ đánh dự kiến',
                      value: manager.selectedDateTime,
                      onTap: () => _pickDateTime(context),
                    ),
                    const SizedBox(height: 12),
                    _DateTimeField(
                      label: 'Thời gian đóng bài',
                      value: manager.expiresAt,
                      helperText: 'Đến giờ này bài sẽ tự động đóng.',
                      onTap: () => _pickCloseDateTime(context),
                    ),
                    const SizedBox(height: 24),

                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Tôi đã đặt sân trước'),
                      value: manager.hasBookedCourt,
                      onChanged: (value) =>
                          manager.toggleHasBookedCourt(value),
                    ),
                    const SizedBox(height: 16),

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: manager.hasBookedCourt
                          ? manager.isLoadingCourts
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(24),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : CourtInfoSection(
                                  selectedCourtId:
                                      manager.selectedCourt?.id,
                                  availableCourts: manager.bookedCourts,
                                  onCourtChanged: manager.updateSelectedCourt,
                                  message: manager.courtMessage,
                                )
                          : const NoCourtInfoBox(),
                    ),

                    const SizedBox(height: 24),

                    MemberInputSection(
                      memberCount: manager.memberCount,
                      controller: manager.memberCountController,
                      onChanged: manager.updateMemberCount,
                    ),
                    const SizedBox(height: 24),

                    PlayStyleSelector(
                      playStyles: manager.playStyleOptions,
                      selectedStyle: manager.selectedPlayStyleLabel,
                      onChanged: manager.selectPlayStyle,
                    ),
                    const SizedBox(height: 24),

                    SkillLevelSelector(
                      skillLevels: manager.skillLevelOptions,
                      selectedLevel: manager.selectedSkillLevelLabel,
                      onChanged: manager.selectSkillLevel,
                    ),
                    const SizedBox(height: 24),

                    NoteField(controller: manager.noteController),
                    const SizedBox(height: 32),

                    SubmitButton(
                      isLoading: manager.isSubmitting,
                      onSubmit: () async {
                        try {
                          final result = await manager.submit();
                          if (context.mounted) {
                            Navigator.of(context).pop(result);
                          }
                        } catch (error) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(error.toString()),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DateTimeField extends StatelessWidget {
  const _DateTimeField({
    required this.label,
    required this.value,
    required this.onTap,
    this.helperText,
  });

  final String label;
  final DateTime value;
  final String? helperText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTap,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              helperText: helperText,
              filled: true,
              fillColor: cs.surfaceVariant.withOpacity(0.6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(DateFormat('HH:mm - dd/MM/yyyy').format(value)),
                const Icon(Icons.calendar_month_outlined),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
