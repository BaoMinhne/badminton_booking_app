import 'package:badminton_booking_app/models/user_details.dart';
import 'package:badminton_booking_app/pages/user/user_manager.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required this.initialDetails});

  final UserDetails initialDetails;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullnameController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _playPerWeekController = TextEditingController();

  static const List<String> _levelOptions = <String>[
    'Beginner',
    'Lower Intermediate',
    'Intermediate',
    'Upper Intermediate',
    'Advanced',
  ];

  static const List<String> _matchTypeOptions = <String>[
    'singles',
    'doubles',
    'mixed',
  ];

  static const Map<String, String> _matchTypeLabels = <String, String>{
    'singles': 'Singles',
    'doubles': 'Doubles',
    'mixed': 'Mixed',
  };

  static const List<String> _playStyleTagOptions = <String>[
    'attack',
    'defense',
    'net',
    'baseline',
    'all_round',
    'fun',
    'competitive',
  ];

  static const Map<String, String> _playStyleLabels = <String, String>{
    'attack': 'Attack',
    'defense': 'Defense',
    'net': 'Net',
    'baseline': 'Baseline',
    'all_round': 'All-round',
    'fun': 'Fun',
    'competitive': 'Competitive',
  };

  static const List<String> _preferredRoleOptions = <String>[
    'front',
    'back',
    'flexible',
  ];

  static const Map<String, String> _preferredRoleLabels = <String, String>{
    'front': 'Front',
    'back': 'Back',
    'flexible': 'Flexible',
  };

  static const List<String> _intensityOptions = <String>[
    'casual',
    'semi_competitive',
    'competitive',
  ];

  static const Map<String, String> _intensityLabels = <String, String>{
    'casual': 'Casual',
    'semi_competitive': 'Semi-competitive',
    'competitive': 'Competitive',
  };

  static const List<String> _genderOptions = <String>[
    'male',
    'female',
  ];

  static const Map<String, String> _genderLabels = <String, String>{
    'male': 'Male',
    'female': 'Female',
  };

  bool _saving = false;
  String? _selectedLevel;
  String? _selectedGender;
  String? _selectedPreferredRole;
  String? _selectedIntensity;
  DateTime? _selectedBirthday;
  List<String> _selectedMatchTypes = <String>[];
  List<String> _selectedPlayStyleTags = <String>[];

  @override
  void initState() {
    super.initState();
    _initFromDetails();
  }

  void _initFromDetails() {
    final details = widget.initialDetails;
    _fullnameController.text = details.fullname ?? '';
    _experienceController.text =
        details.experienceYears != null ? '${details.experienceYears}' : '';
    _playPerWeekController.text =
        details.playsPerWeek != null ? '${details.playsPerWeek}' : '';
    _selectedLevel = _validDropdownValue(details.level, _levelOptions) ??
        _levelFromNumeric(details.levelNumeric);
    _selectedGender = _validDropdownValue(details.gender, _genderOptions);
    _selectedPreferredRole =
        _validDropdownValue(details.preferredRoleDoubles, _preferredRoleOptions);
    _selectedIntensity =
        _validDropdownValue(details.intensity, _intensityOptions);
    _selectedBirthday = details.birthday;
    _selectedMatchTypes = details.matchTypes
        .where((opt) => _matchTypeOptions.contains(opt))
        .toList();
    _selectedPlayStyleTags = details.playStyleTags
        .where((opt) => _playStyleTagOptions.contains(opt))
        .toList();
  }

  @override
  void dispose() {
    _fullnameController.dispose();
    _experienceController.dispose();
    _playPerWeekController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Welcome to Courtify'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Complete your profile to get tailored suggestions.',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'Full name',
                  controller: _fullnameController,
                  validator: (value) =>
                      value == null || value.trim().isEmpty
                          ? 'Please enter your full name'
                          : null,
                ),
                const SizedBox(height: 12),
                _buildDropdown(
                  label: 'Skill level',
                  value: _selectedLevel,
                  options: _levelOptions,
                  onChanged: (value) => setState(() => _selectedLevel = value),
                ),
                const SizedBox(height: 12),
                _buildChips(
                  label: 'Preferred match format',
                  options: _matchTypeOptions,
                  selectedValues: _selectedMatchTypes,
                  onChanged: (newValues) =>
                      setState(() => _selectedMatchTypes = newValues),
                  labelBuilder: (value) =>
                      _matchTypeLabels[value] ?? _titleCase(value),
                ),
                const SizedBox(height: 12),
                _buildChips(
                  label: 'Play style',
                  options: _playStyleTagOptions,
                  selectedValues: _selectedPlayStyleTags,
                  onChanged: (newValues) =>
                      setState(() => _selectedPlayStyleTags = newValues),
                  labelBuilder: (value) =>
                      _playStyleLabels[value] ?? _titleCase(value),
                  maxSelection: 4,
                ),
                const SizedBox(height: 12),
                _buildDropdown(
                  label: 'Preferred doubles position',
                  value: _selectedPreferredRole,
                  options: _preferredRoleOptions,
                  onChanged: (value) =>
                      setState(() => _selectedPreferredRole = value),
                  labelBuilder: (value) =>
                      _preferredRoleLabels[value] ?? _titleCase(value),
                ),
                const SizedBox(height: 12),
                _buildDropdown(
                  label: 'Play intensity',
                  value: _selectedIntensity,
                  options: _intensityOptions,
                  onChanged: (value) => setState(() => _selectedIntensity = value),
                  labelBuilder: (value) =>
                      _intensityLabels[value] ?? _titleCase(value),
                ),
                const SizedBox(height: 12),
                _buildDropdown(
                  label: 'Gender',
                  value: _selectedGender,
                  options: _genderOptions,
                  onChanged: (value) => setState(() => _selectedGender = value),
                  labelBuilder: (value) =>
                      _genderLabels[value] ?? _titleCase(value),
                ),
                const SizedBox(height: 12),
                _buildDatePicker(context),
                const SizedBox(height: 12),
                _buildNumberField(
                  label: 'Years of experience',
                  controller: _experienceController,
                  max: 40,
                ),
                const SizedBox(height: 12),
                _buildNumberField(
                  label: 'Sessions per week',
                  controller: _playPerWeekController,
                  max: 14,
                  min: 0,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _submit,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: const Text('Complete profile'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    FormFieldValidator<String>? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required List<String> options,
    required String? value,
    required ValueChanged<String?> onChanged,
    String Function(String value)? labelBuilder,
  }) {
    final buildLabel = labelBuilder ?? (v) => v;
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      validator: (v) => v == null || v.isEmpty ? 'Please select $label' : null,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: options
          .map(
            (opt) => DropdownMenuItem<String>(
              value: opt,
              child: Text(buildLabel(opt)),
            ),
          )
          .toList(),
    );
  }

  Widget _buildChips({
    required String label,
    required List<String> options,
    required List<String> selectedValues,
    required ValueChanged<List<String>> onChanged,
    int? maxSelection,
    String Function(String value)? labelBuilder,
  }) {
    final buildLabel = labelBuilder ?? (v) => v;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(label,
              style:
                  Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 15)),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((opt) {
            final isSelected = selectedValues.contains(opt);
            return FilterChip(
              label: Text(buildLabel(opt)),
              selected: isSelected,
              onSelected: (selected) {
                final current = List<String>.from(selectedValues);
                if (selected) {
                  if (maxSelection == null || current.length < maxSelection) {
                    current.add(opt);
                  }
                } else {
                  current.remove(opt);
                }
                onChanged(current);
              },
            );
          }).toList(),
        ),
        if (selectedValues.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Please select at least one option',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    final dateText = _selectedBirthday == null
        ? 'Select birthday'
        : DateFormat('dd/MM/yyyy').format(_selectedBirthday!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Birthday',
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(fontSize: 15)),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _pickBirthday,
          icon: const Icon(Icons.event),
          label: Text(dateText),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        if (_selectedBirthday == null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Please select your birthday',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNumberField({
    required String label,
    required TextEditingController controller,
    int? max,
    int min = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      validator: (value) {
        final text = value?.trim() ?? '';
        if (text.isEmpty) return 'Please enter $label';
        final number = int.tryParse(text);
        if (number == null) return 'Invalid value';
        if (number < min) return 'Minimum value is $min';
        if (max != null && number > max) {
          return 'Maximum value is $max';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final initialDate = _selectedBirthday ?? DateTime(now.year - 18, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 80),
      lastDate: now,
    );

    if (picked != null) {
      setState(() {
        _selectedBirthday = picked;
      });
    }
  }

  String _titleCase(String value) {
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }

  int _levelToNumeric(String level) {
    final index = _levelOptions.indexOf(level);
    return index == -1 ? 3 : index + 1;
  }

  String _levelFromNumeric(int numeric) {
    if (numeric <= 0 || numeric > _levelOptions.length) return 'Intermediate';
    return _levelOptions[numeric - 1];
  }

  String? _validDropdownValue(String? value, List<String> options) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return options.contains(normalized) ? normalized : null;
  }

  Future<void> _submit() async {
    final hasValidChips =
        _selectedMatchTypes.isNotEmpty && _selectedPlayStyleTags.isNotEmpty;
    if (!_formKey.currentState!.validate() || !hasValidChips) {
      setState(() {});
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final userManager = context.read<UserManager>();
      final updated = await userManager.updateMyDetails(
        fullname: _fullnameController.text.trim(),
        level: _selectedLevel,
        levelNumeric: _levelToNumeric(_selectedLevel ?? 'Intermediate'),
        matchTypes: _selectedMatchTypes,
        playStyleTags: _selectedPlayStyleTags,
        preferredRoleDoubles: _selectedPreferredRole,
        intensity: _selectedIntensity,
        experienceYears: int.tryParse(_experienceController.text.trim()),
        playsPerWeek: int.tryParse(_playPerWeekController.text.trim()),
        gender: _selectedGender,
        birthday: _selectedBirthday,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarded_${updated.userId}', true);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile completed successfully!')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to save information: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }
}
