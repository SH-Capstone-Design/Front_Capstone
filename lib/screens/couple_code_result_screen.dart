import 'package:flutter/material.dart';

class CoupleCodeResultScreen extends StatelessWidget {
  final String code;
  const CoupleCodeResultScreen({super.key, required this.code});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('커플 코드')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('생성된 커플 코드', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 16),
            Text(
              code,
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
