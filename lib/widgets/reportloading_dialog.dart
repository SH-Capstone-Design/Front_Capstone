import 'dart:async';
import 'package:flutter/material.dart';

class ReportLoadingOverlay extends StatefulWidget {
  final String message;
  final String gifPath;

  const ReportLoadingOverlay({
    super.key,
    this.message = "리포트 작성 중",
    this.gifPath = "assets/images/pencil.gif",
  });

  @override
  State<ReportLoadingOverlay> createState() => _ReportLoadingOverlayState();
}

class _ReportLoadingOverlayState extends State<ReportLoadingOverlay> {
  int dotCount = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // 점 개수를 주기적으로 변경 (. .. ...)
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      setState(() {
        dotCount = (dotCount + 1) % 4; // 0~3 반복
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 완전 투명 배경 (필요하면 Colors.black54 등으로 변경 가능)
        Container(color: Colors.transparent),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                widget.gifPath,
                width: 100,
                height: 100,
              ),
              const SizedBox(height: 16),
              Text(
                '${widget.message}${'.' * dotCount}',
                style: const TextStyle(
                  fontFamily: 'GowunBatang',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
