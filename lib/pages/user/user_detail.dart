import 'package:badminton_booking_app/models/user.dart';
import 'package:badminton_booking_app/models/user_details.dart';
import 'package:badminton_booking_app/pages/user/user_manager.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class UserDetail extends StatefulWidget {
  const UserDetail({super.key});

  @override
  State<UserDetail> createState() => _UserDetailState();
}

class _UserDetailState extends State<UserDetail> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _experienceYearsController =
      TextEditingController();
  final TextEditingController _playsPerWeekController = TextEditingController();

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

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  String? _selectedLevel;
  String? _selectedGender;
  List<String> _selectedMatchTypes = <String>[];
  List<String> _selectedPlayStyleTags = <String>[];
  String? _selectedPreferredRole;
  String? _selectedIntensity;
  DateTime? _selectedBirthday;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userManager = context.read<UserManager>();
      final User? user = await userManager.getCurrentUser();
      final String? userId = await userManager.getCurrentUserId();

      if (!mounted) return;

      if (userId == null) {
        setState(() {
          _error =
              'Không tìm thấy thông tin người dùng. Vui lòng đăng nhập lại.';
          _isLoading = false;
        });
        return;
      }

      UserDetails? details;
      try {
        details = await userManager.getByUserId(userId);
      } catch (_) {
        details = null;
      }

      if (!mounted) return;

      _applyData(user: user, details: details);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Đã xảy ra lỗi khi tải dữ liệu. Vui lòng thử lại sau.';
        _isLoading = false;
      });
    }
  }

  void _applyData({
    User? user,
    UserDetails? details,
  }) {
    if (user != null) {
      _usernameController.text = user.username;
    }

    final String? levelValue = details?.level?.trim();
    final String? level = (levelValue != null && levelValue.trim().isNotEmpty)
        ? levelValue
        : null;
    final String? genderValue = details?.gender?.trim();
    final String? gender =
        (genderValue != null && genderValue.trim().isNotEmpty)
            ? genderValue
            : null;

    final List<String> matchTypes =
        List<String>.from(details?.matchTypes ?? const <String>[])
            .where((style) => style.trim().isNotEmpty)
            .toList();

    final List<String> playStyleTags =
        List<String>.from(details?.playStyleTags ?? const <String>[])
            .where((tag) => tag.trim().isNotEmpty)
            .toList();

    final DateTime? birthday = details?.birthday;

    _fullNameController.text = details?.fullname ?? '';
    _experienceYearsController.text =
        details?.experienceYears?.toString() ?? '';
    _playsPerWeekController.text = details?.playsPerWeek?.toString() ?? '';

    if (birthday != null) {
      _birthdayController.text = DateFormat('dd/MM/yyyy').format(birthday);
    } else {
      _birthdayController.clear();
    }

    setState(() {
      _selectedLevel = level ?? _levelFromNumeric(details?.levelNumeric ?? 3);
      _selectedGender = gender;
      _selectedMatchTypes = List<String>.from(matchTypes);
      _selectedPlayStyleTags = List<String>.from(playStyleTags);
      _selectedPreferredRole = details?.preferredRoleDoubles;
      _selectedIntensity = details?.intensity;
      _selectedBirthday = birthday;
      _isLoading = false;
      _error = null;
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _birthdayController.dispose();
    _experienceYearsController.dispose();
    _playsPerWeekController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin cá nhân'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadDetails,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Tải lại',
          ),
        ],
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadDetails,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDetails,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          Text(
            'Bạn có thể chạm vào các ô thông tin bên dưới để chỉnh sửa.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          _buildField(
            'Tên đăng nhập',
            _usernameController,
            readOnly: true,
          ),
          _buildField(
            'Họ và tên',
            _fullNameController,
            hintText: 'Nhập họ tên của bạn',
          ),
          _buildDropdownField(
            label: 'Trình độ',
            value: _selectedLevel,
            options: _levelOptions,
            hintText: 'Vui lòng chọn trình độ',
            onChanged: (String? value) {
              setState(() {
                _selectedLevel = value;
              });
            },
          ),
          _buildMatchTypeMultiSelect(),
          _buildPlayStyleTagsMultiSelect(),
          _buildDropdownField(
            label: 'Vị trí ưa thích khi đánh đôi',
            value: _selectedPreferredRole,
            options: _preferredRoleOptions,
            hintText: 'Chọn vị trí',
            onChanged: (String? value) {
              setState(() {
                _selectedPreferredRole = value;
              });
            },
          ),
          _buildDropdownField(
            label: 'Cường độ chơi',
            value: _selectedIntensity,
            options: _intensityOptions,
            hintText: 'Chọn cường độ',
            onChanged: (String? value) {
              setState(() {
                _selectedIntensity = value;
              });
            },
          ),
          _buildNumberField(
            'Số năm kinh nghiệm',
            _experienceYearsController,
            hintText: 'Ví dụ: 2',
          ),
          _buildNumberField(
            'Số buổi/tuần',
            _playsPerWeekController,
            hintText: 'Ví dụ: 3',
          ),
          _buildDropdownField(
            label: 'Giới tính',
            value: _selectedGender,
            options: _genderOptions,
            hintText: 'Vui lòng chọn giới tính',
            onChanged: (String? value) {
              setState(() {
                _selectedGender = value;
              });
            },
          ),
          _buildField(
            'Ngày sinh',
            _birthdayController,
            hintText: 'Định dạng dd/MM/yyyy',
            readOnly: true,
            onTap: _pickBirthday,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _saveDetails,
              icon: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(_isSaving ? 'Đang lưu...' : 'LƯU THAY ĐỔI'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    String? hintText,
    String? helperText,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            readOnly: readOnly,
            onTap: onTap,
            onChanged: onChanged,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hintText,
              helperText: helperText,
              filled: true,
              fillColor:
                  Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField(
    String label,
    TextEditingController controller, {
    String? hintText,
    ValueChanged<String>? onChanged,
  }) {
    return _buildField(
      label,
      controller,
      hintText: hintText,
      onChanged: onChanged,
      keyboardType: TextInputType.number,
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> options,
    required String hintText,
    required ValueChanged<String?> onChanged,
  }) {
    final List<String> dropdownOptions = List<String>.from(options);
    if (value != null && value.isNotEmpty && !dropdownOptions.contains(value)) {
      dropdownOptions.insert(0, value);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value:
                value != null && dropdownOptions.contains(value) ? value : null,
            decoration: InputDecoration(
              hintText: hintText,
              filled: true,
              fillColor:
                  Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            hint: Text(hintText),
            items: dropdownOptions
                .map(
                  (String option) => DropdownMenuItem<String>(
                    value: option,
                    child: Text(_beautify(option)),
                  ),
                )
                .toList(),
            onChanged: (String? selected) {
              onChanged(selected);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMatchTypeMultiSelect() {
    final List<String> options = List<String>.from(_matchTypeOptions);
    for (final String selected in _selectedMatchTypes) {
      if (!options.contains(selected)) {
        options.add(selected);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Hình thức tham gia',
          filled: true,
          fillColor:
              Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_selectedMatchTypes.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Vui lòng chọn một hoặc nhiều lựa chọn bên dưới.',
                  style: TextStyle(color: Theme.of(context).hintColor),
                ),
              ),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: options.map((String option) {
                final bool isSelected = _selectedMatchTypes.contains(option);
                return FilterChip(
                  label: Text(_beautify(option)),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        if (!_selectedMatchTypes.contains(option)) {
                          _selectedMatchTypes =
                              List<String>.from(_selectedMatchTypes)
                                ..add(option);
                        }
                      } else {
                        _selectedMatchTypes = _selectedMatchTypes
                            .where((String item) => item != option)
                            .toList();
                      }
                    });
                  },
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  selectedColor:
                      Theme.of(context).colorScheme.primary.withOpacity(0.15),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayStyleTagsMultiSelect() {
    final List<String> options = List<String>.from(_playStyleTagOptions);
    for (final String selected in _selectedPlayStyleTags) {
      if (!options.contains(selected)) {
        options.add(selected);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Phong cách chơi',
          filled: true,
          fillColor:
              Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_selectedPlayStyleTags.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Chọn các thẻ mô tả phong cách của bạn.',
                  style: TextStyle(color: Theme.of(context).hintColor),
                ),
              ),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: options.map((String option) {
                final bool isSelected = _selectedPlayStyleTags.contains(option);
                return FilterChip(
                  label: Text(_beautify(option)),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        if (!_selectedPlayStyleTags.contains(option)) {
                          _selectedPlayStyleTags =
                              List<String>.from(_selectedPlayStyleTags)
                                ..add(option);
                        }
                      } else {
                        _selectedPlayStyleTags = _selectedPlayStyleTags
                            .where((String item) => item != option)
                            .toList();
                      }
                    });
                  },
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  selectedColor:
                      Theme.of(context).colorScheme.primary.withOpacity(0.15),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _beautify(String value) {
    if (value.isEmpty) return value;
    final String normalized = value.replaceAll('_', ' ');
    final List<String> parts = normalized.split(' ');
    return parts
        .map((String part) =>
            part.isEmpty ? part : part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }

  String _levelFromNumeric(int levelNumeric) {
    switch (levelNumeric) {
      case 1:
        return 'Beginner';
      case 2:
        return 'Lower Intermediate';
      case 3:
        return 'Intermediate';
      case 4:
        return 'Upper Intermediate';
      case 5:
        return 'Advanced';
      default:
        return 'Intermediate';
    }
  }

  Future<void> _pickBirthday() async {
    FocusScope.of(context).unfocus();
    final DateTime initialDate = _selectedBirthday ??
        DateTime(
            DateTime.now().year - 18, DateTime.now().month, DateTime.now().day);

    final DateTime firstDate = DateTime(1900);
    final DateTime lastDate = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(firstDate) ? firstDate : initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() {
        _selectedBirthday = picked;
        _birthdayController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _saveDetails() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _isSaving = true;
    });

    try {
      final userManager = context.read<UserManager>();
      final int? parsedExperience =
          int.tryParse(_experienceYearsController.text.trim());
      final int? parsedPlaysPerWeek =
          int.tryParse(_playsPerWeekController.text.trim());
      final updatedDetails = await userManager.updateMyDetails(
        fullname: _fullNameController.text.trim(),
        level: _selectedLevel,
        matchTypes: _selectedMatchTypes,
        playStyleTags: _selectedPlayStyleTags,
        preferredRoleDoubles: _selectedPreferredRole,
        intensity: _selectedIntensity,
        experienceYears: parsedExperience,
        playsPerWeek: parsedPlaysPerWeek,
        gender: _selectedGender,
        birthday: _selectedBirthday,
        homeCourtId: null,
      );

      if (!mounted) return;

      _applyData(details: updatedDetails);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật thông tin thành công.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể lưu thông tin. Vui lòng thử lại sau. ($e)'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
