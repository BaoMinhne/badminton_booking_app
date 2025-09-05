import 'package:badminton_booking_app/components/my_button.dart';
import 'package:badminton_booking_app/components/my_text_field.dart';
import 'package:badminton_booking_app/pages/login_page.dart';
import 'package:badminton_booking_app/pages/nav_bar_page.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class SignUpPage extends StatelessWidget {
  SignUpPage({super.key});

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwdController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController confirmPWController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'S I G N - U P',
          style: TextStyle(
            fontSize: 24,
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
            Padding(
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
                          initialCountryCode: 'VN', // mặc định Việt Nam
                        ),
                      ),
                      const SizedBox(height: 20),
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
                      ),
                      const SizedBox(height: 20),
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
                      ),
                      const SizedBox(height: 20),
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
                      ),
                      const SizedBox(height: 20),
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
                      ),
                      const SizedBox(height: 20),
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
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    )),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      MyButton(
                        text: "Sign Up",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => NavBarPage()),
                          );
                        },
                      ),
                    ],
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
