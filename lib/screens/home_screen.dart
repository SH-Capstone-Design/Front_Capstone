import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectbeat/core/constants.dart';
import 'package:connectbeat/providers/couple_date_provider.dart';
import 'package:connectbeat/providers/user_provider.dart';
import 'package:connectbeat/widgets/bottom_bar.dart';
import 'package:connectbeat/widgets/rounded_button.dart';
import 'myprofile_setting_screen.dart';
import 'setting_screen.dart';
import 'create_chat_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 2;
  late PageController _pageController;

  // 👁️ 캐릭터 깜빡임 제어
  late Timer _blinkTimer;
  bool _isEyeOpen = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userProvider.notifier).fetchUser();
    });

    // 👁️ 1초마다 눈 깜빡임 토글
    _blinkTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _isEyeOpen = !_isEyeOpen;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _blinkTimer.cancel(); // 👁️ 타이머 정리
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final coupleDateNotifier = ref.watch(coupleDateProvider.notifier);

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final screens = [
      Container(), // 대화 기록 화면
      Container(), // 캐릭터 화면
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // ✅ 프로필 카드
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MyProfileSettingScreen(),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: user['profileImage'] != null &&
                            user['profileImage']!.isNotEmpty
                            ? NetworkImage(user['profileImage'])
                            : AssetImage(AppConstants.logoPath) as ImageProvider,
                        backgroundColor: Colors.grey[200],
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user['nickname'] ?? '닉네임 없음',
                            style: const TextStyle(
                              fontFamily: 'GowunBatang',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            coupleDateNotifier.getDDayText(),
                            style: const TextStyle(
                              fontFamily: 'GowunBatang',
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ✅ 오늘의 10분 대화 버튼 (RoundedButton 적용)
              RoundedButton(
                text: "오늘의 10분 대화 하러가기",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateChatScreen(),
                    ),
                  );
                },
              ),

              const Spacer(),

              // ✅ 캐릭터 깜빡임
              Container(
                margin: const EdgeInsets.only(bottom: 80), // 하단바랑 겹치지 않게 띄움
                height: 200,
                child: Center(
                  child: Image.asset(
                    _isEyeOpen
                        ? 'assets/images/ConnectBeatCharacter.png'
                        : 'assets/images/ConnectBeatCharacter2.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      const SettingScreen(),
    ];

    return WillPopScope(
      onWillPop: () async {
        // 뒤로가기 동작 막기
        return false;
      },
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() => _currentIndex = index);
          },
          children: screens,
        ),
        bottomNavigationBar: BottomBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() => _currentIndex = index);
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
        ),
      ),
    );
  }
}
