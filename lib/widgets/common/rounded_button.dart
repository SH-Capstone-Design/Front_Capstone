import 'package:flutter/material.dart';

class RoundedButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final double height;
  final double width;
  final double fontSize;
  final TextStyle? textStyle;

  const RoundedButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.width = double.infinity,
    this.height = 56,
    this.fontSize = 22,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFF0F9), // 연한 핑크
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
