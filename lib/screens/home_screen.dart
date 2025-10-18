// lib/screens/home_screen.dart

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
  if (couple != null && couple['partnerId'] != null) {
    ref.read(sessionControllerProvider.notifier).setPartner(couple['partnerId']);
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
  late Timer _chatImageTimer;

  bool _isEyeOpen = true;
  final List<String> _eyeImages = [
    'assets/images/ConnectBeatCharacter.png',
    'assets/images/ConnectBeatCharacter2.png',
  ];

  final List<String> _chatImages = [
    'assets/images/Chat1.png',
    'assets/images/Chat2.png',
    'assets/images/Chat3.png',
  ];
  int _currentChatImageIndex = 0;

  StreamSubscription? _eventSubscription;
  bool _hasNavigatedToChat = false; // 중복 채팅방 이동 방지

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);

    // 1️⃣ 유저 정보 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userProvider.notifier).fetchUser();
    });

    // 2️⃣ STOMP 개인 큐 연결 및 이벤트 구독
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final repo = ref.read(chatRepositoryProvider);
      try {
        await repo.connectBase();
        debugPrint("✅ 개인 큐 연결 완료");

        _eventSubscription = repo.eventStream.listen((event) async {
          final userId = ref.read(userProvider).maybeWhen(
            data: (u) => u['userId'] ?? "unknown",
            orElse: () => "unknown",
          );

          // ✅ INVITATION 이벤트 → B만 처리
          if (event.eventType == "INVITATION" &&
              event.payload['chatSessionId'] != null &&
              !_hasNavigatedToChat) {
            final chatSessionId = event.payload['chatSessionId'] as String;
            final inviterId = event.payload['inviterId'] as String?;

            // 자신이 보낸 초대는 무시
            if (inviterId == userId) return;

            // 🔹 B에게 초대 다이얼로그 표시
            if (context.mounted) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => AlertDialog(
                  title: const Text("채팅 초대"),
                  content: Text(
                    "${event.payload['inviterName'] ?? '상대방'}님이 채팅을 초대했습니다.",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context), // 거절
                      child: const Text("거절"),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context); // 다이얼로그 닫기

                        final repo = ref.read(chatRepositoryProvider);

                        // 구독/입장은 수락 시에만
                        if (!repo.isSubscribed(chatSessionId)) {
                          await repo.subscribeRoom(chatSessionId: chatSessionId);
                          await repo.sendJoin(chatSessionId: chatSessionId);
                        }

                        if (context.mounted && !_hasNavigatedToChat) {
                          _hasNavigatedToChat = true;
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatRoomScreen(
                                room: ChatRoom(chatSessionId: chatSessionId),
                                currentUserId: userId,
                                autoStart: false, // B니까 타이머 X
                              ),
                            ),
                          );
                        }
                      },
                      child: const Text("수락"),
                    ),
                  ],
                ),
              );
            }
          }

          // ✅ CONVERSATION_STARTED 이벤트 → 둘 다 입장 시 처리
          if (event.eventType == "CONVERSATION_STARTED" &&
              event.chatSessionId != null &&
              context.mounted &&
              !_hasNavigatedToChat) {
            _hasNavigatedToChat = true;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ChatRoomScreen(
                  room: ChatRoom(chatSessionId: event.chatSessionId!),
                  currentUserId: userId,
                  autoStart: false, // ✅ 이벤트 수신자는 수락자처럼 행동
                ),
              ),
            );
          }
        });
      } catch (e) {
        debugPrint("❌ 개인 큐 연결 실패: $e");
      }
    });

    // 3️⃣ 캐릭터 눈 깜빡임 애니메이션
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      for (var imagePath in _eyeImages) {
        await precacheImage(AssetImage(imagePath), context);
      }
      _blinkTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() => _isEyeOpen = !_isEyeOpen);
      });
    });

    // 4️⃣ 10분 대화 이미지 사이클
    _chatImageTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;
      setState(() {
        _currentChatImageIndex =
            (_currentChatImageIndex + 1) % _chatImages.length;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _blinkTimer.cancel();
    _chatImageTimer.cancel();
    _eventSubscription?.cancel();
    super.dispose();
  }

  /// ✅ 대화 세션 생성 또는 참여
  Future<void> _startChat(
      BuildContext context, String userId, String partnerId) async {
    final repo = ref.read(chatRepositoryProvider);
    final sessionCtrl = ref.read(sessionControllerProvider.notifier);
    final sessionState = ref.read(sessionControllerProvider);

    if (partnerId.isEmpty || partnerId == "unknown") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("상대방 정보가 없습니다. 커플 연결을 먼저 완료하세요.")),
      );
      return;
    }

    try {
      // 기존 세션 존재 시 재입장
      if (sessionState.chatSessionId != null &&
          sessionState.chatSessionId!.isNotEmpty) {
        final chatSessionId = sessionState.chatSessionId!;
        if (!repo.isSubscribed(chatSessionId)) {
          await repo.subscribeRoom(chatSessionId: chatSessionId);
          await repo.sendJoin(chatSessionId: chatSessionId);
        }

        if (!_hasNavigatedToChat && context.mounted) {
          _hasNavigatedToChat = true;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ChatRoomScreen(
                room: ChatRoom(chatSessionId: chatSessionId),
                currentUserId: userId,
                autoStart: true, // ✅ A도 재입장 시 타이머 주체
              ),
            ),
          );
        }
        return;
      }

      // 새 세션 생성 (A측)
      debugPrint("🆕 새로운 세션 생성 시작 (A측)");
      final ChatRoom room = await repo.startSession();
      sessionCtrl.setSession(room.chatSessionId);
      debugPrint("✅ 세션 생성 완료: ${room.chatSessionId}");

      // 방 구독
      await repo.subscribeRoom(chatSessionId: room.chatSessionId);
      debugPrint("✅ 방 구독 완료 → ${room.chatSessionId}");

      // 초대 전송
      await repo.sendInvite(
        chatSessionId: room.chatSessionId,
        inviteeId: partnerId,
      );
      debugPrint("💌 초대 전송 완료 → $partnerId");

      // ✅ 생성한 방으로 바로 이동 (A측)
      if (!_hasNavigatedToChat && context.mounted) {
        _hasNavigatedToChat = true;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ChatRoomScreen(
              room: room,
              currentUserId: userId,
              autoStart: true, // ✅ A는 타이머 시작 주체
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
            final partnerId =
                ref.watch(sessionControllerProvider).partnerId ?? "unknown";

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
                      const Spacer(flex: 2),
                      Column(
                        children: [
                          GestureDetector(
                            onTap: () => _startChat(context, userId, partnerId),
                            child: Image.asset(
                              _chatImages[_currentChatImageIndex],
                              width: 120,
                              height: 120,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _startChat(context, userId, partnerId),
                            child: const Text(
                              '10분 대화하기',
                              style: TextStyle(
                                fontFamily: 'GowunBatang',
                                fontSize: 15,
                                color: Colors.black,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(flex: 1),
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        height: 350,
                        child: Center(
                          child: Image.asset(
                            _isEyeOpen ? _eyeImages[0] : _eyeImages[1],
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const Spacer(flex: 1),
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
                    onPageChanged: (index) =>
                        setState(() => _currentIndex = index),
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
              body: Center(child: CircularProgressIndicator())),
          error: (err, st) => const Scaffold(
              body: Center(child: Text('커플 정보를 불러올 수 없습니다.'))),
        );
      },
      loading: () =>
      const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, st) => const Scaffold(
          body: Center(child: Text('사용자 정보를 불러올 수 없습니다.'))),
    );
  }
}
