import 'package:flutter/material.dart';

class CoupleConnectButton extends StatelessWidget {
  const CoupleConnectButton({Key? key, this.onPressed}) : super(key: key);

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF8E7F6),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500
          ),
          elevation: 0,
        ),
        child: const Text('커플 연결하기'),
      ),
    );
  }
}
