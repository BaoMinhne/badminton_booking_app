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
  final TextEditingController _levelController = TextEditingController();
  final TextEditingController _playStyleController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();

  bool _isLoading = true;
  String? _error;

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
    _usernameController.text = user?.username ?? '';
    _fullNameController.text = details?.fullname ?? '';
    _levelController.text = details?.level ?? '';
    _playStyleController.text = (details?.playStyle ?? const [])
        .where((style) => style.trim().isNotEmpty)
        .join(', ');
    _genderController.text = details?.gender ?? '';

    if (details?.birthday != null) {
      _birthdayController.text =
          DateFormat('dd/MM/yyyy').format(details!.birthday!);
    } else {
      _birthdayController.clear();
    }

    setState(() {
      _isLoading = false;
      _error = null;
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _levelController.dispose();
    _playStyleController.dispose();
    _genderController.dispose();
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
          _buildField('Tên đăng nhập', _usernameController,
              helperText: 'Tên tài khoản PocketBase.'),
          _buildField('Họ và tên', _fullNameController,
              hintText: 'Nhập họ tên của bạn'),
          _buildField('Trình độ', _levelController,
              hintText: 'Ví dụ: Beginner, Intermediate...'),
          _buildField('Lối chơi yêu thích', _playStyleController,
              hintText: 'Ví dụ: singles, doubles'),
          _buildField('Giới tính', _genderController,
              hintText: 'Ví dụ: male, female'),
          _buildField('Ngày sinh', _birthdayController,
              hintText: 'Định dạng dd/MM/yyyy'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Chức năng lưu chưa được triển khai
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Chức năng lưu chưa được hỗ trợ.')),
              );
            },
            child: const Text('LƯU THAY ĐỔI'),
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
}
