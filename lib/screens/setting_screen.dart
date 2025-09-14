import 'package:flutter/material.dart';
import 'package:connectbeat/core/constants.dart';
import 'package:connectbeat/widgets/rounded_button.dart';
import 'package:connectbeat/widgets/bottom_bar.dart';
import 'package:connectbeat/services/auth_service.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  int _currentIndex = 3; // 설정 화면은 3

  void _onTabTapped(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/history');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/character');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/home-screen');
        break;
      case 3:
      // 현재 화면이므로 아무것도 안함
        break;
    }
  }

  Future<void> _logout() async {
    // 로그아웃 확인 팝업 띄우기
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('확인'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      // 토큰 및 인증 정보 삭제
      await AuthService.deleteToken();
      await AuthService.deleteGoogleIdToken();

      // 로그인 화면으로 이동 (기존 스택 제거)
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

                  const Center(
                    child: Text(
                      '설정',
                      style: TextStyle(
                        fontSize: 35,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

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

                  // 로그아웃 버튼 (팝업 포함)
                  RoundedButton(
                    text: "로그아웃",
                    onPressed: _logout,
                  ),

                  const Spacer(flex: 3),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
