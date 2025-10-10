import 'dart:async';
import 'package:connectbeat/models/chat_room.dart';
import 'package:connectbeat/screens/character_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectbeat/core/constants.dart';
import 'package:connectbeat/providers/couple_date_provider.dart';
import 'package:connectbeat/providers/user_provider.dart';
import 'package:connectbeat/providers/session_provider.dart'; // ✅ 추가
import 'package:connectbeat/widgets/bottom_bar.dart';
import 'setting_screen.dart';
import '../services/couple_service.dart';
import 'chat_report_list_screen.dart';
import 'chat_room_screen.dart'; // ✅ 채팅방 이동용 import

/// ✅ 커플 상태 Provider (API 실패 시 기본값 반환)
final coupleStatusProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final couple = await CoupleService.fetchCoupleStatus();
  return couple ?? {'partnerNickname': '파트너 없음'};
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 2;
  late PageController _pageController;

  // 👁️ 눈 깜빡임 제어
  late Timer _blinkTimer;
  bool _isEyeOpen = true;

  final List<String> _eyeImages = [
    'assets/images/ConnectBeatCharacter.png',
    'assets/images/ConnectBeatCharacter2.png',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);

    // ⚡ 유저 정보 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userProvider.notifier).fetchUser();
    });

    // 👁️ 눈 깜빡임 애니메이션
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      for (var imagePath in _eyeImages) {
        await precacheImage(AssetImage(imagePath), context);
      }

      _blinkTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() => _isEyeOpen = !_isEyeOpen);
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _blinkTimer.cancel();
    super.dispose();
  }

  bool _navigatedToChat = false; // 🔹 클래스 상단에 추가
  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);
    final coupleDateNotifier = ref.watch(coupleDateProvider.notifier);
    final coupleAsync = ref.watch(coupleStatusProvider);
    final sessionId = ref.watch(sessionControllerProvider); // ✅ 세션 상태 구독

    // ✅ B가 A의 세션 생성을 감지했을 때 자동 이동
    // ✅ B가 A의 세션 생성을 감지했을 때 자동 이동
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_navigatedToChat && sessionId != null && sessionId.isNotEmpty) {
        _navigatedToChat = true; // ✅ 한 번만 이동하도록 플래그 설정
        debugPrint("💞 세션 감지됨: $sessionId → 채팅방으로 이동");

        Navigator.pushReplacementNamed(
          context,
          '/chat',
          arguments: {
            'room': ChatRoom(chatSessionId: sessionId),
            'currentUserId': userAsync.value?['userId'] ?? "unknown",
          },
        );
      }
    });


    return userAsync.when(
      data: (user) {
        return coupleAsync.when(
          data: (couple) {
            final partnerNickname = couple['partnerNickname'] ?? '파트너 없음';

            final screens = [
              ChatReportListScreen(coupleId: user['coupleId'] ?? 0),
              const CharacterScreen(),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "${user['nickname'] ?? '닉네임 없음'} ❤️ $partnerNickname",
                                style: const TextStyle(
                                  fontFamily: 'GowunBatang',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                coupleDateNotifier.getDDayText(),
                                style: const TextStyle(
                                  fontFamily: 'GowunBatang',
                                  fontSize: 16,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Image.asset(
                            'assets/images/ConnectBeat_coin.png',
                            width: 30,
                            height: 30,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '10 개',
                            style: TextStyle(
                              fontFamily: 'GowunBatang',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // ✅ 오늘의 10분 대화 하러가기
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/topic-select');
                          },
                          child: const Text(
                            '오늘의 10분 대화 하러가기',
                            style: TextStyle(
                              fontFamily: 'GowunBatang',
                              fontSize: 18,
                              color: Colors.black,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.black,
                            ),
                          ),
                        ),
                      ),

                      const Spacer(),

                      Container(
                        margin: const EdgeInsets.only(bottom: 1),
                        height: 350,
                        child: Center(
                          child: Image.asset(
                            _isEyeOpen ? _eyeImages[0] : _eyeImages[1],
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
              onWillPop: () async => false,
              child: Scaffold(
                body: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(AppConstants.backgroundHomePath),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentIndex = index);
                    },
                    children: screens,
                  ),
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
          },
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (err, st) => Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('커플 정보를 불러올 수 없습니다.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.refresh(coupleStatusProvider),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, st) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('사용자 정보를 불러올 수 없습니다.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(userProvider.notifier).fetchUser(),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
