import 'package:badminton_booking_app/pages/user/user_manager.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, this.onCompleted});

  final VoidCallback? onCompleted;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final TextEditingController _fullnameController = TextEditingController();
  final TextEditingController _experienceYearsController =
      TextEditingController();
  final TextEditingController _playsPerWeekController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();

  static const Map<String, int> _levelToNumeric = {
    'Beginner': 1,
    'Lower Intermediate': 2,
    'Intermediate': 3,
    'Upper Intermediate': 4,
    'Advanced': 5,
  };

  static const List<String> _levelOptions = _levelToNumeric.keys.toList();

  static const List<String> _matchTypeOptions = <String>[
    'singles',
    'doubles',
    'mixed',
  ];

  static const List<String> _playStyleTagOptions = <String>[
    'attack',
    'defense',
    'net',
    'baseline',
    'all_round',
    'fun',
    'competitive',
  ];

  static const List<String> _preferredRoleOptions = <String>[
    'front',
    'back',
    'flexible',
  ];

  static const List<String> _intensityOptions = <String>[
    'casual',
    'semi_competitive',
    'competitive',
  ];

  static const List<String> _genderOptions = <String>[
    'male',
    'female',
  ];

  bool _isSubmitting = false;
  DateTime? _selectedBirthday;
  String? _selectedLevel;
  List<String> _selectedMatchTypes = <String>[];
  List<String> _selectedPlayStyleTags = <String>[];
  String? _selectedPreferredRole;
  String? _selectedIntensity;
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    _prefillFromDetails();
  }

  void _prefillFromDetails() {
    final details = context.read<UserManager>().myDetails;
    if (details == null) return;

    _fullnameController.text = details.fullname ?? '';
    _experienceYearsController.text =
        details.experienceYears?.toString() ?? '';
    _playsPerWeekController.text = details.playsPerWeek?.toString() ?? '';
    _selectedLevel = details.level ??
        _levelToNumeric.entries
            .firstWhere(
              (entry) => entry.value == details.levelNumeric,
              orElse: () => const MapEntry('Intermediate', 3),
            )
            .key;
    _selectedMatchTypes = List<String>.from(details.matchTypes);
    _selectedPlayStyleTags = List<String>.from(details.playStyleTags);
    _selectedPreferredRole = details.preferredRoleDoubles;
    _selectedIntensity = details.intensity;
    _selectedGender = details.gender;
    _selectedBirthday = details.birthday;

    if (details.birthday != null) {
      _birthdayController.text =
          DateFormat('dd/MM/yyyy').format(details.birthday!);
    }
  }

  @override
  void dispose() {
    _fullnameController.dispose();
    _experienceYearsController.dispose();
    _playsPerWeekController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  int _mapLevelToNumeric(String? level) {
    if (level == null || level.trim().isEmpty) return 3;
    return _levelToNumeric[level.trim()] ?? 3;
  }

  bool _isFormValid() {
    return _fullnameController.text.trim().isNotEmpty &&
        _selectedLevel != null &&
        _selectedMatchTypes.isNotEmpty &&
        _selectedPlayStyleTags.isNotEmpty &&
        _selectedPreferredRole != null &&
        _selectedIntensity != null &&
        _selectedGender != null &&
        _selectedBirthday != null &&
        int.tryParse(_experienceYearsController.text.trim()) != null &&
        int.tryParse(_playsPerWeekController.text.trim()) != null;
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final initialDate = _selectedBirthday ?? DateTime(now.year - 18, now.month);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 80),
      lastDate: DateTime(now.year - 6),
    );

    if (picked != null) {
      setState(() {
        _selectedBirthday = picked;
        _birthdayController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _submit() async {
    if (!_isFormValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đầy đủ thông tin trước khi tiếp tục.'),
        ),
      );
      return;
    }

    final experienceYears = int.tryParse(_experienceYearsController.text.trim());
    final playsPerWeek = int.tryParse(_playsPerWeekController.text.trim());

    if (experienceYears == null || playsPerWeek == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số năm kinh nghiệm hoặc số buổi/tuần không hợp lệ.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userManager = context.read<UserManager>();
      await userManager.updateMyDetails(
        fullname: _fullnameController.text.trim(),
        level: _selectedLevel,
        levelNumeric: _mapLevelToNumeric(_selectedLevel),
        matchTypes: _selectedMatchTypes,
        playStyleTags: _selectedPlayStyleTags,
        preferredRoleDoubles: _selectedPreferredRole,
        intensity: _selectedIntensity,
        experienceYears: experienceYears,
        playsPerWeek: playsPerWeek,
        gender: _selectedGender,
        birthday: _selectedBirthday,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật hồ sơ thành công!')),
      );
      widget.onCompleted?.call();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Có lỗi xảy ra: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 20),
                    _buildTextField(
                      label: 'Họ và tên',
                      controller: _fullnameController,
                      hintText: 'Nhập họ tên đầy đủ của bạn',
                    ),
                    _buildDropdown(
                      label: 'Trình độ hiện tại',
                      value: _selectedLevel,
                      options: _levelOptions,
                      hintText: 'Chọn trình độ',
                      onChanged: (value) => setState(() => _selectedLevel = value),
                    ),
                    _buildChipSelector(
                      label: 'Hình thức tham gia',
                      options: _matchTypeOptions,
                      selected: _selectedMatchTypes,
                      onSelected: (value) {
                        setState(() {
                          if (_selectedMatchTypes.contains(value)) {
                            _selectedMatchTypes.remove(value);
                          } else {
                            _selectedMatchTypes.add(value);
                          }
                        });
                      },
                    ),
                    _buildChipSelector(
                      label: 'Phong cách chơi',
                      options: _playStyleTagOptions,
                      selected: _selectedPlayStyleTags,
                      onSelected: (value) {
                        setState(() {
                          if (_selectedPlayStyleTags.contains(value)) {
                            _selectedPlayStyleTags.remove(value);
                          } else {
                            _selectedPlayStyleTags.add(value);
                          }
                        });
                      },
                    ),
                    _buildDropdown(
                      label: 'Vị trí ưa thích khi đánh đôi',
                      value: _selectedPreferredRole,
                      options: _preferredRoleOptions,
                      hintText: 'Chọn vị trí',
                      onChanged: (value) =>
                          setState(() => _selectedPreferredRole = value),
                    ),
                    _buildDropdown(
                      label: 'Cường độ chơi',
                      value: _selectedIntensity,
                      options: _intensityOptions,
                      hintText: 'Chọn cường độ',
                      onChanged: (value) => setState(() => _selectedIntensity = value),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildNumberField(
                            label: 'Số năm kinh nghiệm',
                            controller: _experienceYearsController,
                            hintText: 'Ví dụ: 3',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildNumberField(
                            label: 'Số buổi/tuần',
                            controller: _playsPerWeekController,
                            hintText: 'Ví dụ: 2',
                          ),
                        ),
                      ],
                    ),
                    _buildDropdown(
                      label: 'Giới tính',
                      value: _selectedGender,
                      options: _genderOptions,
                      hintText: 'Chọn giới tính',
                      onChanged: (value) => setState(() => _selectedGender = value),
                    ),
                    _buildDateField(),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submit,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.check_circle_outline_rounded),
                        label: Text(_isSubmitting ? 'Đang lưu...' : 'Hoàn tất'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Bạn có thể thay đổi thông tin này trong hồ sơ cá nhân sau này.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.sports_tennis, color: colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Text(
              'Chào mừng đến Courtify!',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Hãy hoàn thành hồ sơ để chúng tôi có thể gợi ý sân, bạn chơi và giải đấu phù hợp với bạn nhất.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hintText,
              filled: true,
              fillColor:
                  Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.35),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            readOnly: readOnly,
            onTap: onTap,
            keyboardType: keyboardType,
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField({
    required String label,
    required TextEditingController controller,
    String? hintText,
  }) {
    return _buildTextField(
      label: label,
      controller: controller,
      hintText: hintText,
      keyboardType: TextInputType.number,
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> options,
    required String hintText,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: value != null && options.contains(value) ? value : null,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hintText,
              filled: true,
              fillColor:
                  Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.35),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            items: options
                .map(
                  (option) => DropdownMenuItem<String>(
                    value: option,
                    child: Text(_beautify(option)),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildChipSelector({
    required String label,
    required List<String> options,
    required List<String> selected,
    required ValueChanged<String> onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options
                .map(
                  (option) => FilterChip(
                    label: Text(_beautify(option)),
                    selected: selected.contains(option),
                    onSelected: (_) => onSelected(option),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField() {
    return _buildTextField(
      label: 'Ngày sinh',
      controller: _birthdayController,
      hintText: 'dd/MM/yyyy',
      readOnly: true,
      onTap: _pickBirthday,
    );
  }

  String _beautify(String value) {
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) =>
            word.isEmpty ? word : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
