import 'package:flutter/material.dart';

class LoginButton extends StatelessWidget {
  final String imagePath;
  final double width;
  final double height;
  final VoidCallback onPressed;

  const LoginButton({
    super.key,
    required this.imagePath,
    required this.onPressed,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.deferToChild, // 이미지 영역만 터치 가능
      child: Image.asset(
        imagePath,
        width: width,
        height: height,
        fit: BoxFit.contain, // 이미지 비율 유지
      ),
    );
  }
}
