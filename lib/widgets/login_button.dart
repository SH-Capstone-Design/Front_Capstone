import 'package:flutter/material.dart';

class LoginButton extends StatelessWidget {
  final String imagePath;
  final double height;
  final VoidCallback onPressed;

  const LoginButton({
    super.key,
    required this.imagePath,
    required this.height,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Image.asset(
        imagePath,
        height: height,
      ),
    );
  }
}
