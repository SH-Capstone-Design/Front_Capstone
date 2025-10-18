import 'dart:async';
import 'package:connectbeat/models/chat_room.dart';
import 'package:connectbeat/screens/chat_room_screen.dart';
import 'package:connectbeat/screens/character_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectbeat/core/constants.dart';
import 'package:connectbeat/providers/couple_date_provider.dart';
import 'package:connectbeat/providers/user_provider.dart';
import 'package:connectbeat/providers/session_provider.dart';
import 'package:connectbeat/providers/chat_repository_provider.dart';
import 'package:connectbeat/widgets/bottom_bar.dart';
import 'setting_screen.dart';
import '../services/couple_service.dart';
import 'chat_report_list_screen.dart';

/// ✅ 커플 상태 Provider
final coupleStatusProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final couple = await CoupleService.fetchCoupleStatus();
  // ✅ 커플 상태가 존재하고 partnerId가 있으면 SessionController에 저장
  if (couple != null && couple['partnerId'] != null) {
    ref.read(sessionControllerProvider.notifier)
        .setPartner(couple['partnerId']);
  }
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

    // ✅ 1️⃣ 유저 정보 불러오기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userProvider.notifier).fetchUser();
    });

    // ✅ 2️⃣ STOMP 개인 큐 연결 (초대 수신 대기)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final repo = ref.read(chatRepositoryProvider);
      try {
        await repo.connectBase();
        debugPrint("✅ 개인 큐 연결 완료 (초대 수신 대기 중)");
      } catch (e) {
        debugPrint("❌ 개인 큐 연결 실패: $e");
      }
    });

    // ✅ 3️⃣ 캐릭터 눈 깜빡임 애니메이션
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

  /// ✅ 대화 세션 생성 및 채팅방 이동 (A측)
  Future<void> _startChat(BuildContext context, String userId, String partnerId) async {
    final repo = ref.read(chatRepositoryProvider);
    final sessionCtrl = ref.read(sessionControllerProvider.notifier);

    if (partnerId.isEmpty || partnerId == "unknown") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("상대방 정보가 없습니다. 커플 연결을 먼저 완료하세요.")),
      );
      return;
    }

    try {
      // 1️⃣ 세션 생성 (POST /api/chat/rooms)
      final ChatRoom room = await repo.startSession();
      sessionCtrl.setSession(room.chatSessionId); // ✅ 세션ID 저장
      debugPrint("✅ 세션 생성 완료: ${room.chatSessionId}");

      // 2️⃣ 방 구독 (/topic/chat/room/{id})
      await repo.subscribeRoom(chatSessionId: room.chatSessionId);
      debugPrint("✅ 방 구독 완료: ${room.chatSessionId}");

      // 3️⃣ 초대 전송 (/app/chat/invite)
      await repo.sendInvite(
        chatSessionId: room.chatSessionId,
        inviteeId: partnerId,
      );
      debugPrint("💌 초대 전송 완료 → $partnerId");

      // 4️⃣ 채팅방 화면으로 이동
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatRoomScreen(
              room: room,
              currentUserId: userId,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ 대화 시작 실패: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("대화 시작 실패: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);
    final coupleDateNotifier = ref.watch(coupleDateProvider.notifier);
    final coupleAsync = ref.watch(coupleStatusProvider);

    return userAsync.when(
      data: (user) {
        return coupleAsync.when(
          data: (couple) {
            final partnerNickname = couple['partnerNickname'] ?? '파트너 없음';
            final userId = user['userId'] ?? "unknown";

            // ✅ SessionController에서 partnerId 읽기
            final sessionState = ref.watch(sessionControllerProvider);
            final partnerId = sessionState.partnerId ?? "unknown";

            final screens = [
              ChatReportListScreen(coupleId: user['coupleId'] ?? 0),
              const CharacterScreen(),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      // 🔹 상단 닉네임 & 커플 정보
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
                      // 🔹 코인 표시
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Image.asset('assets/images/ConnectBeat_coin.png',
                              width: 30, height: 30),
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
                      // ✅ 오늘의 10분 대화 버튼
                      Center(
                        child: GestureDetector(
                          onTap: () => _startChat(context, userId, partnerId),
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
                      // 🔹 캐릭터
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
          loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (err, st) => const Scaffold(
              body: Center(child: Text('커플 정보를 불러올 수 없습니다.'))),
        );
      },
      loading: () =>
      const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, st) =>
      const Scaffold(body: Center(child: Text('사용자 정보를 불러올 수 없습니다.'))),
    );
  }
}
