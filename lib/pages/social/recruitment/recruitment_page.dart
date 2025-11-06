import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/court_service.dart';
import '../../social/social_manager.dart';
import '../recruitment/widgets/court_info_section.dart';
import '../recruitment/widgets/intro_card.dart';
import '../recruitment/widgets/member_input_section.dart';
import '../recruitment/widgets/no_court_info_box.dart';
import '../recruitment/widgets/note_field.dart';
import '../recruitment/widgets/play_style_selector.dart';
import '../recruitment/widgets/skill_level_selector.dart';
import '../recruitment/widgets/submit_button.dart';

class RecruitmentFormPage extends StatefulWidget {
  const RecruitmentFormPage({super.key});

  @override
  State<RecruitmentFormPage> createState() => _RecruitmentFormPageState();
}

class _RecruitmentFormPageState extends State<RecruitmentFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _locationNoteController = TextEditingController();
  late final TextEditingController _memberCountController;

  final CourtService _courtService = CourtService();

  bool _hasBookedCourt = true;
  bool _isSubmitting = false;
  bool _isLoadingCourts = true;
  int _memberCount = 3;
  String _selectedSkillLevel = 'Intermediate';
  String _selectedPlayStyle = 'doubles';
  String? _selectedCourtId;
  DateTime _selectedDateTime = DateTime.now().add(const Duration(hours: 2));
  String? _courtErrorMessage;

  List<CourtOption> _availableCourts = const [];

  final List<PlayStyleOption> _playStyles = const [
    PlayStyleOption(value: 'singles', label: 'Đánh đơn'),
    PlayStyleOption(value: 'doubles', label: 'Đánh đôi'),
    PlayStyleOption(value: 'mixed', label: 'Đánh đôi nam nữ'),
  ];

  final List<SkillLevelOption> _skillLevels = const [
    SkillLevelOption(value: 'Beginner', label: 'Mới chơi'),
    SkillLevelOption(value: 'Lower Intermediate', label: 'Trung bình yếu'),
    SkillLevelOption(value: 'Intermediate', label: 'Trung bình'),
    SkillLevelOption(value: 'Upper Intermediate', label: 'Trung bình khá'),
    SkillLevelOption(value: 'Advanced', label: 'Nâng cao'),
  ];

  @override
  void initState() {
    super.initState();
    _memberCountController =
        TextEditingController(text: _memberCount.toString());
    _loadCourts();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _locationNoteController.dispose();
    _memberCountController.dispose();
    super.dispose();
  }

  Future<void> _loadCourts() async {
    setState(() {
      _isLoadingCourts = true;
      _courtErrorMessage = null;
    });

    try {
      final courts = await _courtService.listCourts(
        perPage: 200,
        filter: "is_active = true",
      );

      setState(() {
        _availableCourts = courts
            .map(
              (court) => CourtOption(
                id: court.id,
                name: '${court.name} - ${court.location}',
              ),
            )
            .toList(growable: false);
        if (_availableCourts.isNotEmpty) {
          _selectedCourtId = _availableCourts.first.id;
        }
      });
    } on CourtServiceException catch (error) {
      setState(() => _courtErrorMessage = error.message);
    } catch (error) {
      setState(() => _courtErrorMessage = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoadingCourts = false);
      }
    }
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

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_hasBookedCourt && (_selectedCourtId == null || _selectedCourtId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn sân bạn đã đặt.')),
      );
      return;
    }

    final socialManager = context.read<SocialFeedManager>();
    final content = _noteController.text.trim();
    final locationNote =
        _hasBookedCourt ? null : _locationNoteController.text.trim();

    setState(() => _isSubmitting = true);

    try {
      await socialManager.createRecruitmentPost(
        content: content,
        requiredMembers: _memberCount,
        courtId: _hasBookedCourt ? _selectedCourtId : null,
        eventTime: _hasBookedCourt ? _selectedDateTime : null,
        skillLevel: _selectedSkillLevel,
        playStyle: _selectedPlayStyle,
        locationNote: locationNote,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng bài tuyển thành viên thành công.')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Tạo bài tuyển thành viên')),
      body: SafeArea(
        child: Form(
          key: _formKey,
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
                  value: _hasBookedCourt,
                  onChanged: (value) {
                    setState(() {
                      _hasBookedCourt = value;
                      if (!value) {
                        _selectedCourtId = null;
                      } else if (_availableCourts.isNotEmpty) {
                        _selectedCourtId ??= _availableCourts.first.id;
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _hasBookedCourt
                      ? _buildCourtSection(cs)
                      : _buildNoCourtSection(textTheme),
                ),
                const SizedBox(height: 24),
                MemberInputSection(
                  memberCount: _memberCount,
                  controller: _memberCountController,
                  onChanged: (val) => setState(() => _memberCount = val),
                ),
                const SizedBox(height: 24),
                PlayStyleSelector(
                  playStyles: _playStyles,
                  selectedValue: _selectedPlayStyle,
                  onChanged: (value) => setState(() => _selectedPlayStyle = value),
                ),
                const SizedBox(height: 24),
                SkillLevelSelector(
                  skillLevels: _skillLevels,
                  selectedValue: _selectedSkillLevel,
                  onChanged: (value) => setState(() => _selectedSkillLevel = value),
                ),
                const SizedBox(height: 24),
                NoteField(controller: _noteController),
                if (!_hasBookedCourt) ...[
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _locationNoteController,
                    decoration: const InputDecoration(
                      labelText: 'Gợi ý khu vực hoặc địa điểm mong muốn',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                SubmitButton(
                  onSubmit: _handleSubmit,
                  isLoading: _isSubmitting,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCourtSection(ColorScheme cs) {
    if (_isLoadingCourts) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: CircularProgressIndicator(color: cs.primary),
        ),
      );
    }

    if (_availableCourts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surfaceVariant.withOpacity(0.6),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          _courtErrorMessage ?? 'Bạn chưa có sân nào để chọn. Vui lòng tạo sân trước.',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
      );
    }

    return CourtInfoSection(
      selectedCourtId: _selectedCourtId,
      availableCourts: _availableCourts,
      selectedDateTime: _selectedDateTime,
      onCourtChanged: (value) => setState(() => _selectedCourtId = value),
      onPickDateTime: _pickDateTime,
    );
  }

  Widget _buildNoCourtSection(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const NoCourtInfoBox(),
        const SizedBox(height: 12),
        Text(
          'Bạn có thể mô tả khu vực mong muốn ở phần bên dưới.',
          style: textTheme.bodySmall,
        ),
      ],
    );
  }
}
