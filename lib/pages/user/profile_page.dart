import 'dart:io';

import 'package:badminton_booking_app/components/my_icon_button.dart';

import 'package:badminton_booking_app/models/user_details.dart';
import 'package:badminton_booking_app/pages/auth/auth_manager.dart';
import 'package:badminton_booking_app/pages/auth/login_page.dart';
import 'package:badminton_booking_app/pages/user/user_detail.dart';
import 'package:badminton_booking_app/pages/user/user_manager.dart';
import 'package:badminton_booking_app/utils/dialog_utils.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late UserManager _userManager;
  bool _loading = true;

  String? avatarFileUrl;

  final ImagePicker _picker = ImagePicker();

  bool _isLoading = true;
  bool _isUploading = false;
  UserDetails? _details;
  String? _avatarUrl;
  String? _username;

  @override
  void initState() {
    super.initState();
    _userManager = context.read<UserManager>();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final userManager = context.read<UserManager>();
      final user = await userManager.getCurrentUser();
      String? userID = await userManager.getCurrentUserId();

      if (userID == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final details = await userManager.getByUserId(userID);
      if (!mounted) return;
      setState(() {
        _details = details;
        _avatarUrl = details?.avatarUrl;
        _isLoading = false;
        _username = user?.username ?? 'User';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    if (_isUploading) return;

    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null) {
        return;
      }

      final file = File(picked.path);

      setState(() {
        _isUploading = true;
      });

      final userManager = context.read<UserManager>();
      final updatedDetails = await userManager.uploadAvatar(file);
      if (!mounted) return;

      if (updatedDetails != null) {
        setState(() {
          _avatarUrl = updatedDetails;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Cập nhật ảnh đại diện thành công.',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Không thể tải ảnh lên. Vui lòng thử lại.',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải ảnh: $error')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Container(
              padding: EdgeInsets.only(),
              height: MediaQuery.of(context).size.height / 2,
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                    'assets/images/profile_background.jpeg',
                  ),
                  fit: BoxFit.contain,
                  alignment: Alignment.topCenter,
                ),
              ),
            ),
            Container(
              padding:
                  EdgeInsets.only(left: 20, top: 40, right: 20, bottom: 40),
              margin: EdgeInsets.only(
                top: MediaQuery.of(context).size.height / 4.5,
              ),
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 100),
                  // box chức năng
                  Container(
                    padding: EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                        width: 2,
                      ),
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 2), // bóng dưới
                        ),
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, -2), // bóng trên
                        ),
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(2, 0), // bóng phải
                        ),
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(-2, 0), // bóng trái
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        MyIconButton(
                          icon: Icons.person,
                          title: "Personal",
                          color: Theme.of(context).colorScheme.primary,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => UserDetail()),
                            );
                          },
                        ),
                        MyIconButton(
                          icon: Icons.lock,
                          title: "Password",
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        MyIconButton(
                          icon: Icons.card_giftcard,
                          title: "Voucher",
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        MyIconButton(
                          icon: Icons.verified,
                          title: "Membership",
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                  ),

                  // list chức năng
                  SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Activities",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          SizedBox(height: 5),
                          _buildListItem(
                              context, Icons.calendar_month, "Booking History"),
                          SizedBox(height: 15),
                          Text(
                            "Systems",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          SizedBox(height: 5),
                          _buildListItem(context, Icons.info_outline_rounded,
                              "Version information: 1.0.0"),
                          SizedBox(height: 10),
                          _buildListItem(
                            context,
                            Icons.logout,
                            "Logout",
                            onTap: () async {
                              final confirm = await showConfirmDialog(
                                context,
                                'Bạn có chắc chắn muốn đăng xuất?',
                                title: 'Đăng xuất',
                              );

                              if (!confirm) return;

                              try {
                                await context.read<AuthManager>().logout();

                                if (!context.mounted) return;

                                // Xoá toàn bộ stack và quay về LoginPage
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                      builder: (_) => LoginPage()),
                                  (route) => false,
                                );
                              } catch (e) {
                                if (!context.mounted) return;
                                await showErrorDialog(
                                    context, 'Đăng xuất thất bại: $e');
                              }
                            },
                          ),
                          SizedBox(height: 80),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
            // Avatar
            Positioned(
              top: MediaQuery.of(context).size.height / 4 - 80,
              child: Column(
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        SizedBox(width: 5),
                        MyIconButton(
                          icon: Icons.notifications,
                          title: "",
                          color: const Color.fromARGB(255, 63, 160, 113),
                        ),
                        Stack(
                          children: [
                            _buildAvatar(60),
                            Positioned(
                              bottom: 2,
                              right: 5,
                              child: GestureDetector(
                                onTap:
                                    _isUploading ? null : _pickAndUploadAvatar,
                                child: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.camera_alt,
                                    size: 22,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        MyIconButton(
                          icon: Icons.calendar_today,
                          title: "",
                          color: const Color.fromARGB(255, 207, 162, 48),
                        ),
                        SizedBox(width: 5),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    _username!,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(double radius) {
    if (_isLoading) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey.shade200,
        child: CircularProgressIndicator(),
      );
    }

    if (_avatarUrl == null || _avatarUrl!.isEmpty) {
      return CircleAvatar(
          radius: radius, child: Icon(Icons.person, size: radius));
    }

    final url = _avatarUrl!;

    // Local file
    if (url.startsWith('file://')) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white,
        foregroundImage: FileImage(File(Uri.parse(url).toFilePath())),
      );
    }
    if (url.startsWith('/')) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white,
        foregroundImage: FileImage(File(url)),
      );
    }

    // Remote http(s)
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white,
      foregroundImage: NetworkImage(url),
      onForegroundImageError: (_, __) {},
    );
  }
}

Widget _buildListItem(BuildContext context, IconData icon, String title,
    {VoidCallback? onTap}) {
  return Container(
    decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 0), // bóng dưới
          ),
        ]),
    child: ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.secondary),
      title: Text(title),
      trailing: Icon(Icons.arrow_forward_ios, size: 20, color: Colors.grey),
      onTap: onTap,
    ),
  );
}
