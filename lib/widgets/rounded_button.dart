import 'package:flutter/material.dart';

class RoundedButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;

  const RoundedButton({
    super.key,
    required this.text,
    this.onPressed,
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
            // 눌림 효과: 안쪽으로 들어간 듯한 그림자
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
            // 평소 그림자
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
          style: const TextStyle(
            fontFamily: 'GowunBatang',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
