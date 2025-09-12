import 'package:flutter/material.dart';

class MyTextfield extends StatelessWidget {
  final String hintText;
  final bool obscureText;
  final TextEditingController controller;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final bool enabled;
  final int? maxLines;
  final VoidCallback? onTap;
  final bool isReadOnly;
  final String? Function(String?)? validator;

  const MyTextfield({
    super.key,
    required this.hintText,
    this.obscureText = false,
    required this.controller,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.enabled = true,
    this.maxLines = 1,
    this.onTap,
    this.isReadOnly = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(14),
      child: TextFormField(
        onTap: onTap,
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        enabled: enabled,
        readOnly: isReadOnly,
        maxLines: obscureText ? 1 : maxLines,
        decoration: InputDecoration(
          hintText: hintText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
          ),
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
        ),
        validator: validator,
      ),
    );
  }
}
