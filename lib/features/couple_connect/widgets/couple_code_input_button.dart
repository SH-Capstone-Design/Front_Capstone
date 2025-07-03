import 'package:flutter/material.dart';
import '../../../widgets/common/rounded_button.dart';

class CoupleCodeInputButton extends StatelessWidget {
  final VoidCallback onPressed;

  const CoupleCodeInputButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return RoundedButton(
      text: '커플 코드 입력',
      onPressed: onPressed,
      width: 280,
      height: 62,
      fontSize: 27, // (22 + 5)
    );
  }
}
