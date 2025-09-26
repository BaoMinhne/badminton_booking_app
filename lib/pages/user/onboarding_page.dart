import 'package:badminton_booking_app/pages/user/user_manager.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const _levelOptions = <String>[
    'Beginner',
    'Intermediate',
    'Advanced',
    'Professional',
  ];

  static const _genderOptions = <String>[
    'male',
    'female',
    'other',
  ];

  static const _playStyleOptions = <String>[
    'Singles',
    'Doubles',
    'Mixed Doubles',
  ];

  final _fullNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int _currentStep = 0;
  DateTime? _birthday;
  String? _gender;
  String? _level;
  final Set<String> _playStyles = <String>{};

  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final userManager = context.read<UserManager>();
      final details = await userManager.getMyDetails();
      if (details != null) {
        _fullNameController.text = details.fullname ?? '';
        _birthday = details.birthday;
        _gender = details.gender;
        _level = details.level;
        _playStyles
          ..clear()
          ..addAll(details.playStyle);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể tải thông tin ban đầu: $e'),
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    super.dispose();
  }

  List<Step> _buildSteps() {
    return [
      Step(
        title: const Text('Thông tin'),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: 'Họ và tên',
                hintText: 'Nhập họ và tên của bạn',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập họ và tên';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Ngày sinh',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _birthday == null
                        ? 'Chưa chọn'
                        : DateFormat('dd/MM/yyyy').format(_birthday!),
                  ),
                ),
                TextButton(
                  onPressed: _pickBirthday,
                  child: const Text('Chọn ngày'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Ngày sinh giúp chúng tôi đưa ra gợi ý phù hợp hơn.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
      Step(
        title: const Text('Trình độ'),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Giới tính',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _genderOptions
                  .map(
                    (gender) => ChoiceChip(
                      label: Text(gender.toUpperCase()),
                      selected: _gender == gender,
                      onSelected: (selected) {
                        if (_submitting) return;
                        setState(() {
                          _gender = selected ? gender : null;
                        });
                      },
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            Text(
              'Trình độ chơi',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _levelOptions
                  .map(
                    (level) => ChoiceChip(
                      label: Text(level),
                      selected: _level == level,
                      onSelected: (selected) {
                        if (_submitting) return;
                        setState(() {
                          _level = selected ? level : null;
                        });
                      },
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
      Step(
        title: const Text('Phong cách'),
        isActive: _currentStep >= 2,
        state:
            _currentStep > 2 ? StepState.complete : StepState.indexed,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn thường chơi kiểu nào?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _playStyleOptions
                  .map(
                    (style) => FilterChip(
                      label: Text(style),
                      selected: _playStyles.contains(style),
                      onSelected: (selected) {
                        if (_submitting) return;
                        setState(() {
                          if (selected) {
                            _playStyles.add(style);
                          } else {
                            _playStyles.remove(style);
                          }
                        });
                      },
                    ),
                  )
                  .toList(),
            ),
            if (_playStyles.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'Chọn ít nhất một phong cách chơi để tiếp tục.',
                  style: TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    ];
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final initialDate = _birthday ?? DateTime(now.year - 18, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(1950),
      lastDate: now,
      initialDate: initialDate,
      helpText: 'Chọn ngày sinh',
      cancelText: 'Huỷ',
      confirmText: 'Chọn',
    );
    if (picked != null) {
      setState(() {
        _birthday = picked;
      });
    }
  }

  void _handleStepContinue() {
    if (_currentStep == 0) {
      if (_formKey.currentState?.validate() != true) {
        return;
      }
      setState(() {
        _currentStep += 1;
      });
      return;
    }

    if (_currentStep == 1) {
      if (_gender == null || _level == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn giới tính và trình độ.')),
        );
        return;
      }
      setState(() {
        _currentStep += 1;
      });
      return;
    }

    if (_playStyles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất một phong cách chơi.')),
      );
      return;
    }

    _submit();
  }

  Future<void> _submit() async {
    if (_submitting) return;

    setState(() {
      _submitting = true;
    });

    try {
      final userManager = context.read<UserManager>();
      await userManager.updateMyDetails(
        fullname: _fullNameController.text.trim(),
        birthday: _birthday,
        gender: _gender,
        level: _level,
        playStyles: _playStyles.toList(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hoàn tất thông tin thành công!'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể lưu thông tin: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _submitting = false;
      });
    }
  }

  void _handleStepCancel() {
    if (_currentStep == 0 || _submitting) {
      return;
    }
    setState(() {
      _currentStep -= 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Hoàn thiện hồ sơ của bạn'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Stepper(
            type: StepperType.horizontal,
            currentStep: _currentStep,
            onStepContinue: _submitting ? null : _handleStepContinue,
            onStepCancel: _handleStepCancel,
            controlsBuilder: (context, details) {
              final isLastStep = _currentStep == _buildSteps().length - 1;
              return Row(
                children: [
                  ElevatedButton(
                    onPressed: details.onStepContinue,
                    child: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isLastStep ? 'Hoàn tất' : 'Tiếp tục'),
                  ),
                  const SizedBox(width: 8),
                  if (_currentStep > 0)
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: const Text('Quay lại'),
                    ),
                ],
              );
            },
            steps: _buildSteps(),
          ),
        ),
      ),
    );
  }
}
