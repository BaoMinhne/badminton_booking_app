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

class RecruitmentFormPage extends StatefulWidget {
  const RecruitmentFormPage({super.key});

  @override
  State<RecruitmentFormPage> createState() => _RecruitmentFormPageState();
}

class _RecruitmentFormPageState extends State<RecruitmentFormPage> {
  // Controllers
  final TextEditingController _noteController = TextEditingController();
  late final TextEditingController _memberCountController;

  // State chính
  bool _hasBookedCourt = true;
  int _memberCount = 3;
  String _skillLevel = 'Trung bình khá';
  String _playStyle = 'Đánh đôi';
  String? _selectedCourt;
  DateTime _selectedDateTime = DateTime.now().add(const Duration(hours: 2));

  // Dữ liệu mẫu
  final List<String> _availableCourts = const [
    'Sân Quận 7 - Court A',
    'Sân Quận 1 - Court B',
    'Sân Phú Nhuận - Court C',
  ];

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

  @override
  void initState() {
    super.initState();
    _selectedCourt = _availableCourts.first;
    _memberCountController =
        TextEditingController(text: _memberCount.toString());
  }

  @override
  void dispose() {
    _noteController.dispose();
    _memberCountController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (time == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
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

              // 🔘 Toggle
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Tôi đã đặt sân trước'),
                value: _hasBookedCourt,
                onChanged: (value) => setState(() => _hasBookedCourt = value),
              ),
              const SizedBox(height: 16),

              // 🏸 Nếu đã đặt sân / chưa đặt sân
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _hasBookedCourt
                    ? CourtInfoSection(
                        selectedCourt: _selectedCourt!,
                        availableCourts: _availableCourts,
                        selectedDateTime: _selectedDateTime,
                        onCourtChanged: (v) =>
                            setState(() => _selectedCourt = v),
                        onPickDateTime: _pickDateTime,
                      )
                    : NoCourtInfoBox(),
              ),

              const SizedBox(height: 24),

              // 👥 Nhập số lượng
              MemberInputSection(
                memberCount: _memberCount,
                controller: _memberCountController,
                onChanged: (val) => setState(() => _memberCount = val),
              ),
              const SizedBox(height: 24),

              // 🏸 Lối chơi
              PlayStyleSelector(
                playStyles: _playStyles,
                selectedStyle: _playStyle,
                onChanged: (v) => setState(() => _playStyle = v),
              ),
              const SizedBox(height: 24),

              // 💪 Trình độ
              SkillLevelSelector(
                skillLevels: _skillLevels,
                selectedLevel: _skillLevel,
                onChanged: (v) => setState(() => _skillLevel = v),
              ),
              const SizedBox(height: 24),

              // 📝 Ghi chú
              NoteField(controller: _noteController),
              const SizedBox(height: 32),

              // 🚀 Nút đăng
              SubmitButton(onSubmit: () {
                print('--- THÔNG TIN BÀI TUYỂN ---');
                print('Đã đặt sân: $_hasBookedCourt');
                print('Sân: $_selectedCourt');
                print('Giờ đánh: $_selectedDateTime');
                print('Số lượng: $_memberCount');
                print('Lối chơi: $_playStyle');
                print('Trình độ: $_skillLevel');
                print('Ghi chú: ${_noteController.text}');
              }),
            ],
          ),
        ),
      ),
    );
  }
}
