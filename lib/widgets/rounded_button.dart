import 'package:flutter/material.dart';

class RoundedButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final double fontSize; // 새 파라미터
  final Color textColor; // 텍스트 색상 옵션

  const RoundedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.fontSize = 20, // 기본값 20
    this.textColor = Colors.black, // 기본값 검정
  });

  @override
  State<RoundedButton> createState() => _RoundedButtonState();
}

class _RoundedButtonState extends State<RoundedButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        alignment: Alignment.center,
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFFFEEFF),
          borderRadius: BorderRadius.circular(15),
          boxShadow: _isPressed
              ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              offset: const Offset(2, 2),
              blurRadius: 7,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.7),
              offset: const Offset(-2, -2),
              blurRadius: 7,
              spreadRadius: 2,
            ),
          ]
              : [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              offset: const Offset(4, 4),
              blurRadius: 10,
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.8),
              offset: const Offset(-4, -4),
              blurRadius: 10,
            ),
          ],
        ),
        child: Text(
          widget.text,
          style: TextStyle(
            fontFamily: 'GowunBatang',
            fontSize: widget.fontSize, // 외부에서 조절 가능
            fontWeight: FontWeight.w600,
            color: widget.textColor,
          ),
        ),
      ),
    );
  }
}
