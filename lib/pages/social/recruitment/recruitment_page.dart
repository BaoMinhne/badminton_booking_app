import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:badminton_booking_app/pages/auth/auth_manager.dart';
import 'package:badminton_booking_app/pages/social/social_manager.dart';
import 'package:badminton_booking_app/pages/social/recruitment/recruitment_form_manager.dart';
import 'package:badminton_booking_app/pages/social/recruitment/widgets/court_info_section.dart';
import 'package:badminton_booking_app/pages/social/recruitment/widgets/intro_card.dart';
import 'package:badminton_booking_app/pages/social/recruitment/widgets/member_input_section.dart';
import 'package:badminton_booking_app/pages/social/recruitment/widgets/no_court_info_box.dart';
import 'package:badminton_booking_app/pages/social/recruitment/widgets/note_field.dart';
import 'package:badminton_booking_app/pages/social/recruitment/widgets/play_style_selector.dart';
import 'package:badminton_booking_app/pages/social/recruitment/widgets/skill_level_selector.dart';
import 'package:badminton_booking_app/pages/social/recruitment/widgets/submit_button.dart';
import 'package:badminton_booking_app/services/recruitment_service.dart';

class RecruitmentFormPage extends StatefulWidget {
  const RecruitmentFormPage({super.key});

  @override
  State<RecruitmentFormPage> createState() => _RecruitmentFormPageState();
}

class _RecruitmentFormPageState extends State<RecruitmentFormPage> {
  final TextEditingController _noteController = TextEditingController();
  late final TextEditingController _memberCountController;

  final List<String> _playStyles = const [
    'Đánh đơn',
    'Đánh đôi',
    'Linh hoạt',
  ];

  final List<String> _skillLevels = const [
    'Mới chơi',
    'Trung bình',
    'Trung bình khá',
    'Nâng cao',
    'Chuyên nghiệp',
  ];

  int _memberCount = 3;
  String _skillLevel = 'Trung bình khá';
  String _playStyle = 'Đánh đôi';
  late final DateTime _initialDateTime;

  @override
  void initState() {
    super.initState();
    _memberCountController = TextEditingController(text: _memberCount.toString());
    _initialDateTime = DateTime.now().add(const Duration(hours: 2));
  }

  @override
  void dispose() {
    _noteController.dispose();
    _memberCountController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(
    BuildContext context,
    RecruitmentFormManager manager,
    String? userId,
  ) async {
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

    await manager.setSelectedDateTime(
      newDateTime,
      userId: userId ?? '',
    );
  }

  Future<void> _handleSubmit(
    BuildContext context,
    RecruitmentFormManager manager,
  ) async {
    final authManager = context.read<AuthManager>();
    final user = authManager.user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn cần đăng nhập để đăng bài.')),
      );
      return;
    }

    if (_memberCount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số lượng thành viên phải lớn hơn 0.')),
      );
      return;
    }

    if (manager.hasBookedCourt && manager.selectedBooking == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn sân đã đặt.')),
      );
      return;
    }

    final note = _noteController.text.trim();
    if (note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hãy nhập mô tả ngắn cho bài tuyển.')),
      );
      return;
    }

    try {
      final post = await manager.submitRecruitmentPost(
        authorId: user.id,
        content: note,
        targetMemberCount: _memberCount,
        skillLevel: _skillLevel,
        playStyle: _playStyle,
      );

      context.read<SocialManager>().addRecruitmentPost(post);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng bài tuyển thành viên thành công.')),
      );
      Navigator.of(context).pop();
    } on RecruitmentServiceException catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final authManager = context.read<AuthManager>();
    final userId = authManager.user?.id;

    return ChangeNotifierProvider<RecruitmentFormManager>(
      create: (_) {
        final manager = RecruitmentFormManager();
        Future.microtask(() {
          manager.initialize(
            hasBookedCourt: userId != null,
            initialDateTime: _initialDateTime,
            userId: userId ?? '',
          );
        });
        return manager;
      },
      child: Consumer<RecruitmentFormManager>(
        builder: (context, manager, _) {
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
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Tôi đã đặt sân trước'),
                      value: manager.hasBookedCourt,
                      onChanged: (value) async {
                        if (userId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Bạn cần đăng nhập để kiểm tra sân đã đặt.'),
                            ),
                          );
                          return;
                        }
                        await manager.toggleHasBookedCourt(
                          value,
                          userId: userId,
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: manager.hasBookedCourt
                          ? _buildCourtSection(context, manager, userId)
                          : const NoCourtInfoBox(),
                    ),
                    const SizedBox(height: 24),
                    MemberInputSection(
                      memberCount: _memberCount,
                      controller: _memberCountController,
                      onChanged: (val) => setState(() {
                        _memberCount = val <= 0 ? 1 : val;
                      }),
                    ),
                    const SizedBox(height: 24),
                    PlayStyleSelector(
                      playStyles: _playStyles,
                      selectedStyle: _playStyle,
                      onChanged: (value) => setState(() => _playStyle = value),
                    ),
                    const SizedBox(height: 24),
                    SkillLevelSelector(
                      skillLevels: _skillLevels,
                      selectedLevel: _skillLevel,
                      onChanged: (value) => setState(() => _skillLevel = value),
                    ),
                    const SizedBox(height: 24),
                    NoteField(controller: _noteController),
                    const SizedBox(height: 32),
                    SubmitButton(
                      onSubmit: () => _handleSubmit(context, manager),
                      isLoading: manager.isSubmitting,
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

  Widget _buildCourtSection(
    BuildContext context,
    RecruitmentFormManager manager,
    String? userId,
  ) {
    if (manager.isCheckingBookings) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    if (manager.availableBookings.isEmpty) {
      final message = manager.bookingMessage ??
          'Bạn chưa có sân nào trong ngày ${DateFormat('dd/MM').format(manager.selectedDateTime)}';
      return NoCourtInfoBox(message: message);
    }

    return CourtInfoSection(
      selectedBooking: manager.selectedBooking,
      availableBookings: manager.availableBookings,
      selectedDateTime: manager.selectedDateTime,
      onBookingChanged: (value) => manager.selectBooking(value),
      onPickDateTime: () => _pickDateTime(context, manager, userId),
    );
  }
}
