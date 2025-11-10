import 'package:flutter/material.dart';

class ReportLoadingDialog extends StatelessWidget {
  final String message;
  final String gifPath;

  const ReportLoadingDialog({
    super.key,
    this.message = "리포트 작성 중...",
    this.gifPath = "assets/images/pencil.gif",
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              gifPath,
              width: 80,
              height: 80,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
