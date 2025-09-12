import 'dart:developer';

import 'package:badminton_booking_app/components/my_button.dart';
import 'package:badminton_booking_app/components/my_text_field.dart';
import 'package:badminton_booking_app/pages/auth/auth_manager.dart';
import 'package:badminton_booking_app/pages/nav_bar_page.dart';
import 'package:badminton_booking_app/pages/auth/sign_up_page.dart';
import 'package:badminton_booking_app/utils/dialog_utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwdController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey();

  @override
  void dispose() {
    emailController.dispose();
    passwdController.dispose();

    super.dispose();
  }

  final _isSubmitting = ValueNotifier<bool>(false);

  Future<void> _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    _isSubmitting.value = true;

    try {
      final email = emailController.text.trim();
      final password = passwdController.text;

      // Sign user up
      await context.read<AuthManager>().login(
            email,
            password,
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
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'L O G I N',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(18),
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
                          'Welcome back to Courtify!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Email & Password
                        const Text(
                          'Email',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        MyTextfield(
                          hintText: "Enter your email...",
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

                        // Password
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
                          suffixIcon: Icon(Icons.remove_red_eye),
                          validator: (v) {
                            if (v == null || v.length < 8) {
                              return 'Mật khẩu tối thiểu 8 ký tự';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 40),
                        ValueListenableBuilder<bool>(
                          valueListenable: _isSubmitting,
                          builder: (_, loading, __) => MyButton(
                            text: loading ? "Wait a second..." : "Login",
                            onTap: loading ? null : () => _submit(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Don't have any account?",
                  style: TextStyle(
                    color: Color(0xFF311937),
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 5),
                GestureDetector(
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => SignUpPage()));
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text("Sign Up Here",
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          )),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: () {},
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 30),
                child: Material(
                  elevation: 2,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          "assets/images/google_logo.png",
                          height: 30,
                          width: 30,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Sign in with Google',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
