import 'package:flutter/material.dart';
import 'package:connectbeat/core/constants.dart';
import 'package:connectbeat/widgets/rounded_button.dart';
import 'package:connectbeat/services/auth_service.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '로그아웃',
          style: TextStyle(fontFamily: 'GowunBatang'),
        ),
        content: const Text(
          '정말 로그아웃하시겠습니까?',
          style: TextStyle(fontFamily: 'GowunBatang'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              '취소',
              style: TextStyle(fontFamily: 'GowunBatang'),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              '확인',
              style: TextStyle(fontFamily: 'GowunBatang'),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await AuthService.deleteToken();
      await AuthService.deleteGoogleIdToken();
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final logoHeight = size.height * 0.2;
    final topPadding = size.height * 0.01;

    return Scaffold(
      body: Stack(
        children: [
          // 배경 이미지
          SizedBox.expand(
            child: Image.asset(
              AppConstants.backgroundPath,
              fit: BoxFit.cover,
            ),
          ),
          // SafeArea + 화면 내용
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.06),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: topPadding),
                  // 로고
                  SizedBox(
                    height: logoHeight,
                    child: Image.asset(
                      AppConstants.logoPath,
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(height: size.height * 0.01),
                  // 화면 제목
                  const Center(
                    child: Text(
                      '설정',
                      style: TextStyle(
                        fontFamily: 'GowunBatang',
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const Spacer(flex: 2),
                  // 버튼들
                  RoundedButton(
                    text: "디데이 설정",
                    onPressed: () {
                      Navigator.pushNamed(context, '/couple-date');
                    },
                  ),
                  SizedBox(height: size.height * 0.03),
                  RoundedButton(
                    text: "커플 관리",
                    onPressed: () {
                      Navigator.pushNamed(context, '/couple-manage');
                    },
                  ),
                  SizedBox(height: size.height * 0.03),
                  RoundedButton(
                    text: "내정보 수정",
                    onPressed: () {
                      Navigator.pushNamed(context, '/myprofile-setting');
                    },
                  ),
                  SizedBox(height: size.height * 0.03),
                  RoundedButton(
                    text: "로그아웃",
                    onPressed: () => _logout(context),
                  ),
                  const Spacer(flex: 3),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
