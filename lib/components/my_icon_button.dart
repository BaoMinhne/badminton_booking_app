import 'package:flutter/material.dart';

class MyIconButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback? onTap;
  const MyIconButton({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
              radius: 28,
              backgroundColor: color,
              child: Icon(
                icon,
                size: 28,
                color: Colors.white,
              )),
          SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 14, color: Colors.black)),
        ],
      ),
    );
  }
}
