import 'package:flutter/material.dart';
import '../../../widgets/common/rounded_button.dart';

class CoupleCodeCreateButton extends StatelessWidget {
  final VoidCallback onPressed;

  const CoupleCodeCreateButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return RoundedButton(
      text: '커플 코드 생성',
      onPressed: onPressed,
      width: 280,
      height: 62,
      fontSize: 27,
    );
  }
}
