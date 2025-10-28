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

  static const List<String> _levelOptions = <String>[
    'Beginner',
    'Lower Intermediate',
    'Intermediate',
    'Upper Intermediate',
    'Advanced',
  ];

  static const List<String> _playStyleOptions = <String>[
    'singles',
    'doubles',
    'mixed',
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
  List<String> _selectedPlayStyles = <String>[];
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

    final String? level =
        (details?.level != null && details!.level!.trim().isNotEmpty)
            ? details.level!.trim()
            : null;
    final String? gender =
        (details?.gender != null && details!.gender!.trim().isNotEmpty)
            ? details.gender!.trim()
            : null;

    final List<String> playStyles =
        List<String>.from(details?.playStyle ?? const <String>[])
            .where((style) => style.trim().isNotEmpty)
            .toList();

    final DateTime? birthday = details?.birthday;

    _fullNameController.text = details?.fullname ?? '';

    if (birthday != null) {
      _birthdayController.text = DateFormat('dd/MM/yyyy').format(birthday);
    } else {
      _birthdayController.clear();
    }

    setState(() {
      _selectedLevel = level;
      _selectedGender = gender;
      _selectedPlayStyles = List<String>.from(playStyles);
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('D E T A I L'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadDetails,
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
          ),
        ],
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
            helperText: 'Tên tài khoản PocketBase.',
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
          _buildMultiSelectField(),
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
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveDetails,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('LƯU THAY ĐỔI'),
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
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            readOnly: readOnly,
            onTap: onTap,
            decoration: InputDecoration(
              hintText: hintText,
              helperText: helperText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value:
                value != null && dropdownOptions.contains(value) ? value : null,
            decoration: InputDecoration(
              hintText: hintText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

  Widget _buildMultiSelectField() {
    final List<String> options = List<String>.from(_playStyleOptions);
    for (final String selected in _selectedPlayStyles) {
      if (!options.contains(selected)) {
        options.add(selected);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Lối chơi yêu thích',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_selectedPlayStyles.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Vui lòng chọn một hoặc nhiều lựa chọn bên dưới.',
                  style: TextStyle(color: Theme.of(context).hintColor),
                ),
              ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options.map((String option) {
                final bool isSelected = _selectedPlayStyles.contains(option);
                return FilterChip(
                  label: Text(_beautify(option)),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        if (!_selectedPlayStyles.contains(option)) {
                          _selectedPlayStyles =
                              List<String>.from(_selectedPlayStyles)
                                ..add(option);
                        }
                      } else {
                        _selectedPlayStyles = _selectedPlayStyles
                            .where((String item) => item != option)
                            .toList();
                      }
                    });
                  },
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
    final List<String> parts = value.split(' ');
    return parts
        .map((String part) =>
            part.isEmpty ? part : part[0].toUpperCase() + part.substring(1))
        .join(' ');
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
      final updatedDetails = await userManager.updateMyDetails(
        fullname: _fullNameController.text.trim(),
        level: _selectedLevel,
        playStyles: _selectedPlayStyles,
        gender: _selectedGender,
        birthday: _selectedBirthday,
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
