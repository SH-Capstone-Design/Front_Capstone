import 'package:flutter/material.dart';
import 'widgets/couple_connect_button.dart';
import 'widgets/nickname_setting_button.dart';
import 'widgets/profile_setting_button.dart';
import '../../features/couple_connect/screens/couple_connect_screen.dart';

class PostLoginSetupScreen extends StatelessWidget {
  const PostLoginSetupScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back, color: Colors.black),
        //   onPressed: () => Navigator.pop(context),
        // ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 상단 Connect Beat 박스
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Connect Beat',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // 중앙 프로필 원형 (아바타)
            const CircleAvatar(
              radius: 56,
              backgroundColor: Color(0xFFF8F1F6),
              // backgroundImage: ... (프로필 이미지가 있다면 설정)
            ),
            const SizedBox(height: 32),
            const ProfileSettingButton(),
            const SizedBox(height: 8),
            const NicknameSettingButton(),
            const Spacer(),
            CoupleConnectButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CoupleCodeScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
          ],

        ),
      ),
    );
  }
}