import 'dart:developer';
import 'package:provider/provider.dart';

import 'package:badminton_booking_app/components/my_button.dart';
import 'package:badminton_booking_app/components/my_text_field.dart';
import 'package:badminton_booking_app/pages/auth/auth_manager.dart';
import 'package:badminton_booking_app/pages/auth/login_page.dart';
import 'package:badminton_booking_app/pages/nav_bar_page.dart';
import 'package:badminton_booking_app/utils/dialog_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwdController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController confirmPWController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  String? _completePhoneNumber;
  final GlobalKey<FormState> _formKey = GlobalKey();

  @override
  void dispose() {
    emailController.dispose();
    passwdController.dispose();
    confirmPWController.dispose();
    nameController.dispose();
    phoneController.dispose();
    _isSubmitting.dispose();
    super.dispose();
  }

  final _isSubmitting = ValueNotifier<bool>(false);

  Future<void> _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (passwdController.text != confirmPWController.text) {
      showErrorDialog(context, 'Password và Confirm password không khớp.');
      return;
    }
    _formKey.currentState!.save();

    _isSubmitting.value = true;

    try {
      final email = emailController.text.trim();
      final password = passwdController.text;
      final rawPhone = _completePhoneNumber ?? phoneController.text;
      final phone = rawPhone.replaceAll(RegExp(r'\s+'), '');
      final username = nameController.text.trim();

      // Sign user up
      await context.read<AuthManager>().signup(
            email,
            password,
            phone,
            username,
          );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const NavBarPage()),
      );
    } catch (e, st) {
      log('signup error: $e', stackTrace: st);
      if (!mounted) return;
      showErrorDialog(context, e.toString());
    } finally {
      _isSubmitting.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'S I G N - U P',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Material(
                  borderRadius: BorderRadius.circular(10),
                  elevation: 2,
                  child: Container(
                    padding: const EdgeInsets.only(
                      top: 30,
                      left: 15,
                      right: 15,
                      bottom: 30,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey[100],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome to Courtify!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        Text(
                          'Create an account to get started.',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const SizedBox(height: 5),

                        // Phone number
                        Material(
                          elevation: 6,
                          borderRadius: BorderRadius.circular(14),
                          child: IntlPhoneField(
                            controller: phoneController,
                            disableLengthCheck: true,
                            decoration: InputDecoration(
                              labelText: 'Your phone number',
                              border: OutlineInputBorder(
                                borderSide: BorderSide(),
                              ),
                            ),
                            initialCountryCode: 'VN',
                            onChanged: (phone) =>
                                _completePhoneNumber = phone.completeNumber,
                            onSaved: (phone) {
                              if (phone != null) {
                                _completePhoneNumber = phone.completeNumber;
                              }
                            },
                            validator: (v) {
                              final value = v?.completeNumber ?? '';
                              if (value.trim().isEmpty) {
                                return 'Vui lòng nhập số điện thoại';
                              }
                              return null;
                            }, // mặc định Việt Nam
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Email field
                        const Text(
                          'Email',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        MyTextfield(
                          hintText: "Enter your Email...",
                          controller: emailController,
                          prefixIcon: const Icon(Icons.email),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Vui lòng nhập email';
                            }
                            if (!v.contains('@')) return 'Email không hợp lệ';
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Username field
                        const Text(
                          'Username',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        MyTextfield(
                          hintText: "Enter your username...",
                          controller: nameController,
                          prefixIcon: const Icon(Icons.person),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Vui lòng nhập username';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Password field
                        const Text(
                          'Password',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        MyTextfield(
                          hintText: "Enter your password...",
                          controller: passwdController,
                          obscureText: true,
                          prefixIcon: const Icon(Icons.password),
                          validator: (v) {
                            if (v == null || v.length < 8) {
                              return 'Mật khẩu tối thiểu 8 ký tự';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Confirm password field
                        const Text(
                          'Comfirm Password',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        MyTextfield(
                          hintText: "Confirm your password...",
                          controller: confirmPWController,
                          obscureText: true,
                          prefixIcon: const Icon(Icons.password),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Vui lòng xác nhận mật khẩu';
                            }
                            if (v != passwdController.text) {
                              return 'Không khớp mật khẩu';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Navigate to Login page
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Already have an account?",
                              style: TextStyle(
                                color: Color(0xFF311937),
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 5),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => LoginPage()));
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text("Login Here",
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      )),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Sign up button
                        ValueListenableBuilder<bool>(
                          valueListenable: _isSubmitting,
                          builder: (_, loading, __) => MyButton(
                            text: loading ? "Signing Up..." : "Sign Up",
                            onTap: loading ? null : () => _submit(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
