// 채팅방 생성Ui
import 'package:flutter/material.dart';
import 'package:connectbeat/core/constants.dart';
import 'package:connectbeat/widgets/rounded_button.dart';
import 'package:connectbeat/widgets/bottom_bar.dart';

class CreateChatScreen extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onNavTap;   // 탭될 때 호출되는 콜백 함수

  const CreateChatScreen({
    super.key,
    this.selectedIndex = 0,
    this.onNavTap = _defaultOnTap,
  });

  static void _defaultOnTap(int idx) {}

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8FC), // 연한 핑크
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: size.height * 0.06),
            // 앱 이름 로고 이미지
            Center(
              child: Image.asset(
                AppConstants.logoPath,
                height: 50,
                fit: BoxFit.contain,
              ),
            ),
            const Spacer(flex: 2),
            // 채팅방 생성 버튼
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: RoundedButton(
                text: "채팅방 생성",
                onPressed: () => Navigator.pushNamed(context, '/invite-partner'),
              ),
            ),
            const Spacer(flex: 3),
          ],
        ),
      ),
      bottomNavigationBar: BottomBar(
        currentIndex: selectedIndex,
        onTap: onNavTap,
      ),
    );
  }
}