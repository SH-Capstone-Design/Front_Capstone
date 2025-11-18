import 'dart:async';
import 'dart:convert';
import 'package:connectbeat/models/chat_room.dart';
import 'package:connectbeat/providers/coin_provider.dart' hide attendanceProvider;
import 'package:connectbeat/providers/inventory_provider.dart';
import 'package:connectbeat/screens/chat_room_screen.dart';
import 'package:connectbeat/screens/character_screen.dart';
import 'package:connectbeat/screens/inventory_screen.dart';
import 'package:connectbeat/services/attendance_service.dart';
import 'package:connectbeat/widgets/attendance_dialog.dart';
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
import '../services/auth_service.dart';
import 'chat_report_list_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
  StreamSubscription? _eventSubscription;

  bool _hasNavigatedToChat = false;
  bool _isAttendanceDialogOpen = false;
  bool _hasCheckedAttendance = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initHome();
      await ref.read(inventoryProvider.notifier).fetchInventory();
      await ref.read(currentDecorationProvider.notifier).fetchCurrentDecoration();
      if (!_hasCheckedAttendance) {
        final canCheckIn = await _canCheckInToday();
        if (canCheckIn && mounted) {
          _hasCheckedAttendance = true;
          await _showAttendanceDialogIfNeeded();
        }
      }
    });
  }

  Future<void> _initHome() async {
    ref.read(userProvider.notifier).fetchUser();
    await ref.read(coinProvider.notifier).loadCoin();
    _loadCoupleDDay();
    _connectStompQueue();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _eventSubscription?.cancel();
    super.dispose();
  }

  /// 🔸 하루 1회 출석 체크
  Future<bool> _canCheckInToday() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheckIn = prefs.getInt('lastCheckIn') ?? 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    return lastCheckIn < today;
  }

  Future<void> _markCheckedInToday() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    await prefs.setInt('lastCheckIn', today);
  }

  Future<void> _showAttendanceDialogIfNeeded() async {
    if (_isAttendanceDialogOpen) return;

    final canCheckIn = await _canCheckInToday();
    if (!canCheckIn) return;

    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) return;

    _isAttendanceDialogOpen = true;
    try {
      final attendanceService = AttendanceService(baseUrl: dotenv.env['BASE_URL']!);
      final result = await attendanceService.checkIn();
      if (!mounted) return;

      if (result['success'] == true) {
        ref.read(coinProvider.notifier).updateCoin(result['newTotalCoinBalance'] ?? 0);
      }

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AttendanceDialog(
          consecutiveDays: result['consecutiveDays'] ?? 0,
          newTotalCoinBalance: result['newTotalCoinBalance'] ?? ref.read(coinProvider),
        ),
      );

      await _markCheckedInToday();
    } catch (e) {
      debugPrint("❌ 출석 체크 실패: $e");
    } finally {
      _isAttendanceDialogOpen = false;
    }
  }

  Future<void> _loadCoupleDDay() async {
    final coupleDateNotifier = ref.read(coupleDateProvider.notifier);
    try {
      final token = await AuthService.getToken();
      if (token != null) {
        final url = Uri.parse('${dotenv.env['BASE_URL']}/couples/status');
        final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final dateStr = data['anniversaryDate'];
          if (dateStr != null) {
            final parsedDate = DateTime.tryParse(dateStr);
            if (parsedDate != null) coupleDateNotifier.setDate(parsedDate);
          }
        }
      }
    } catch (e) {
      debugPrint("💥 커플 상태 불러오기 실패: $e");
    }
  }

  Future<void> _connectStompQueue() async {
    final repo = ref.read(chatRepositoryProvider);
    try {
      await repo.connectBase();
      final pending = await repo.checkPendingInvitation();
      if (pending != null && !_hasNavigatedToChat) {
        _showInvitationDialog(
          chatSessionId: pending['chatSessionId'],
          inviterId: pending['inviterId'],
        );
      }

      _eventSubscription = repo.eventStream.listen((event) async {
        final userId = ref.read(userProvider).maybeWhen(
          data: (u) => u['userId'] ?? "unknown",
          orElse: () => "unknown",
        );

        if (event.eventType == "INVITATION" &&
            event.payload['chatSessionId'] != null &&
            !_hasNavigatedToChat) {
          final chatSessionId = event.payload['chatSessionId'] as String;
          final inviterId = event.payload['inviterId'] as String?;
          if (inviterId != userId && context.mounted) {
            _showInvitationDialog(chatSessionId: chatSessionId, inviterId: inviterId);
          }
        }

        if (event.eventType == "CONVERSATION_STARTED" &&
            event.chatSessionId != null &&
            context.mounted &&
            !_hasNavigatedToChat) {
          _navigateToChat(event.chatSessionId!, userId);
        }
      });
    } catch (e) {
      debugPrint("❌ STOMP 연결 실패: $e");
    }
  }

  void _showInvitationDialog({required String chatSessionId, required String? inviterId}) {
    final coupleStatus = ref.read(coupleStatusProvider).maybeWhen(
      data: (data) => data,
      orElse: () => null,
    );

    String partnerNickname = '상대방';
    if (coupleStatus != null && inviterId != null && coupleStatus['partnerId'] == inviterId) {
      partnerNickname = coupleStatus['partnerNickname'] ?? inviterId;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("채팅 초대"),
        content: Text("$partnerNickname 님이 채팅을 초대했습니다."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(chatRepositoryProvider).sendCancel(chatSessionId: chatSessionId);
              setState(() => _hasNavigatedToChat = false);
            },
            child: const Text("거절"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final repo = ref.read(chatRepositoryProvider);
              if (!repo.isSubscribed(chatSessionId)) {
                await repo.subscribeRoom(chatSessionId: chatSessionId);
                await repo.sendJoin(chatSessionId: chatSessionId);
              }
              if (!_hasNavigatedToChat && context.mounted) {
                _navigateToChat(chatSessionId, ref.read(userProvider).maybeWhen(
                  data: (u) => u['userId'] ?? "unknown",
                  orElse: () => "unknown",
                ));
              }
            },
            child: const Text("수락"),
          ),
        ],
      ),
    );
  }

  void _navigateToChat(String chatSessionId, String userId) {
    _hasNavigatedToChat = true;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ChatRoomScreen(
          room: ChatRoom(chatSessionId: chatSessionId),
          currentUserId: userId,
          autoStart: true,
        ),
      ),
    );
  }

  Future<void> _startChat(BuildContext context, String userId, String partnerId) async {
    final repo = ref.read(chatRepositoryProvider);
    final sessionCtrl = ref.read(sessionControllerProvider.notifier);
    final sessionState = ref.read(sessionControllerProvider);

    if (partnerId.isEmpty || partnerId == "unknown") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("상대방 정보가 없습니다. 커플 연결을 먼저 완료하세요.")),
      );
      return;
    }

    try {
      final chatSessionId = sessionState.chatSessionId;

      if (chatSessionId != null && repo.isSubscribed(chatSessionId)) {
        await repo.sendJoin(chatSessionId: chatSessionId);
        if (!_hasNavigatedToChat && context.mounted) {
          _navigateToChat(chatSessionId, userId);
        }
        return;
      }

      debugPrint("🆕 새로운 세션 생성 시작");
      final ChatRoom room = await repo.startSession();
      sessionCtrl.setSession(room.chatSessionId);

      await repo.subscribeRoom(chatSessionId: room.chatSessionId);
      await repo.sendInvite(chatSessionId: room.chatSessionId, inviteeId: partnerId);

      if (!_hasNavigatedToChat && context.mounted) {
        _navigateToChat(room.chatSessionId, userId);
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
    final coupleAsync = ref.watch(coupleStatusProvider);
    final coupleDate = ref.watch(coupleDateProvider);
    final currentDeco = ref.watch(currentDecorationProvider);

    return userAsync.when(
      data: (user) {
        return coupleAsync.when(
          data: (couple) {
            final partnerNickname = couple['partnerNickname'] ?? '파트너 없음';
            final userId = user['userId'] ?? "unknown";
            final partnerId = ref.watch(sessionControllerProvider).partnerId ?? "unknown";

            final bgUrl = currentDeco?.backgroundItem?.assetUrl ??
                currentDeco?.backgroundItem?.imageUrl ??
                AppConstants.backgroundHomePath;

            final clothesUrl = currentDeco?.clothesItem?.assetUrl ??
                currentDeco?.clothesItem?.imageUrl;

            // 캐릭터+옷 하나만 보여주도록 수정
            final screens = [
              ChatReportListScreen(coupleId: couple['coupleId'] ?? 0),
              const CharacterScreen(),
              SafeArea(
                child: SingleChildScrollView(
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
                                  coupleDate != null
                                      ? '우리가 만난지 ${DateTime.now().difference(coupleDate).inDays + 1}일 🩷'
                                      : '사귄 날짜를 설정해주세요',
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
                        const SizedBox(height: 10),
                        Consumer(
                          builder: (context, ref, _) {
                            final coin = ref.watch(coinProvider);
                            return Align(
                              alignment: Alignment.centerRight,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    'assets/images/ConnectBeat_coin.png',
                                    width: 30,
                                    height: 30,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      '$coin 개',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: 'GowunBatang',
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 30),
                        GestureDetector(
                          onTap: () => _startChat(context, userId, partnerId),
                          child: Image.asset(
                            'assets/images/Chat.gif',
                            width: 190,
                            height: 190,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (clothesUrl != null && clothesUrl.isNotEmpty)
                          SizedBox(
                            height: 350, // 화면 비율에 맞게 조정
                            child: Image.network(
                              clothesUrl,
                              fit: BoxFit.contain,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const InventoryScreen(),
              const SettingScreen(),
            ];


            return WillPopScope(
              onWillPop: () async => false,
              child: Scaffold(
                body: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(bgUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) => setState(() => _currentIndex = index),
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
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (err, st) => const Scaffold(body: Center(child: Text('커플 정보를 불러올 수 없습니다.'))),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, st) => const Scaffold(body: Center(child: Text('사용자 정보를 불러올 수 없습니다.'))),
    );
  }
}