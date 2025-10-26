import 'package:flutter/material.dart';
import 'package:connectbeat/core/constants.dart'; // AppConstants.backgroundPath

class ChatHistoryScreen extends StatelessWidget {
  final String emotion;
  final int minute;

  const ChatHistoryScreen({
    super.key,
    required this.emotion,
    required this.minute,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "$emotion 대화 기록",
          style: const TextStyle(
            fontFamily: 'GowunBatang',
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppConstants.backgroundPath),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Text(
              "$minute분 시점의 $emotion 감정 대화 기록",
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'GowunBatang',
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
