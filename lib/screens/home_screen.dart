// home_screen.dart
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

  StreamSubscription? _stompSubscription;
  StreamSubscription? _eventSubscription;

  bool _hasNavigatedToChat = false;
  bool _isInvitationDialogOpen = false;
  BuildContext? _invitationDialogContext;

  bool _hasCheckedAttendance = false;
  bool _isAttendanceDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initHome();
      _showAttendanceDialogIfNeeded();
    });
  }

  @override
  void dispose() {
    _stompSubscription?.cancel();
    _eventSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initHome() async {
    ref.read(userProvider.notifier).fetchUser();
    await ref.read(coinProvider.notifier).loadCoin();
    await ref.read(inventoryProvider.notifier).fetchInventory();
    await ref.read(currentDecorationProvider.notifier).fetchCurrentDecoration();
    _loadCoupleDDay();
    _connectStompQueue();
  }

  Future<void> _showAttendanceDialogIfNeeded() async {
    if (_hasCheckedAttendance || _isAttendanceDialogOpen) return;

    final user = ref.read(userProvider).maybeWhen(data: (u) => u, orElse: () => null);
    if (user == null) return;

    final userId = user['userId'] ?? "unknown";
    final prefs = await SharedPreferences.getInstance();
    final todayKey = "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}";
    final lastCheckIn = prefs.getString('lastCheckIn_$userId') ?? '';

    if (lastCheckIn == todayKey) {
      _hasCheckedAttendance = true;
      return;
    }

    _isAttendanceDialogOpen = true;

    try {
      final attendanceService = AttendanceService(baseUrl: dotenv.env['BASE_URL']!);
      final status = await attendanceService.getStatus();

      if (!mounted) return;

      if (status['todayChecked'] == true) {
        await prefs.setString('lastCheckIn_$userId', todayKey);
        _hasCheckedAttendance = true;
        return;
      }

      if (context.mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AttendanceDialog(
            newTotalCoinBalance: status['newTotalCoinBalance'] ?? 0,
            consecutiveDays: status['consecutiveDays'] ?? 0,
          ),
        );

        await prefs.setString('lastCheckIn_$userId', todayKey);
        _hasCheckedAttendance = true;
      }
    } catch (e) {
      debugPrint("❌ 출석 상태 확인 실패: $e");
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
      if (pending != null && !_hasNavigatedToChat && mounted) {
        _showInvitationDialog(
          chatSessionId: pending['chatSessionId'],
          inviterId: pending['inviterId'],
        );
      }

      _eventSubscription = repo.eventStream.listen((event) async {
        if (!mounted) return;

        final userId = ref.read(userProvider).maybeWhen(
          data: (u) => u['userId'] ?? "unknown",
          orElse: () => "unknown",
        );

        // 초대 이벤트
        if (event.eventType == "INVITATION" &&
            event.payload['chatSessionId'] != null &&
            !_hasNavigatedToChat) {
          final chatSessionId = event.payload['chatSessionId'] as String;
          final inviterId = event.payload['inviterId'] as String?;
          if (inviterId != userId && context.mounted) {
            _showInvitationDialog(chatSessionId: chatSessionId, inviterId: inviterId);
          }
        }

        // 초대 취소 이벤트
        if (event.eventType == "INVITATION_CANCELED" &&
            event.payload['chatSessionId'] != null) {
          debugPrint("💬 상대방이 초대를 취소했습니다. 다이얼로그 닫기");
          _cancelInvitationDialog();
        }

        // 대화 시작 이벤트
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
    if (_isInvitationDialogOpen || !mounted || !context.mounted) return;

    final coupleStatus = ref.read(coupleStatusProvider).maybeWhen(
      data: (data) => data,
      orElse: () => null,
    );

    String partnerNickname = '상대방';
    if (coupleStatus != null && inviterId != null && coupleStatus['partnerId'] == inviterId) {
      partnerNickname = coupleStatus['partnerNickname'] ?? inviterId;
    }

    _isInvitationDialogOpen = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true, // ★ rootNavigator로 띄우기
      builder: (ctx) {
        _invitationDialogContext = ctx;
        return AlertDialog(
          title: const Text("채팅 초대"),
          content: Text("$partnerNickname 님이 채팅을 초대했습니다."),
          actions: [
            TextButton(
              onPressed: () {
                // 거절 클릭 시 바로 다이얼로그 pop하지 않고
                // 이벤트처럼 _cancelInvitationDialog()를 호출하도록 변경
                ref.read(chatRepositoryProvider).sendCancel(chatSessionId: chatSessionId);
              },
              child: const Text("거절"),
            ),
            TextButton(
              onPressed: () async {
                if (ctx.mounted) Navigator.pop(ctx);
                _isInvitationDialogOpen = false;

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
        );
      },
    );
  }

  void _cancelInvitationDialog() {
    if (_isInvitationDialogOpen) {
      try {
        if (_invitationDialogContext != null &&
            Navigator.of(_invitationDialogContext!, rootNavigator: true).canPop()) {
          Navigator.of(_invitationDialogContext!, rootNavigator: true).pop();
        }
      } catch (e) {
        debugPrint("⚠️ 초대 다이얼로그 닫기 실패: $e");
      } finally {
        _isInvitationDialogOpen = false;
        _invitationDialogContext = null;
      }
    }
  }


  void _navigateToChat(String chatSessionId, String userId) {
    if (!mounted || !context.mounted) return;

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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("상대방 정보가 없습니다. 커플 연결을 먼저 완료하세요.")),
        );
      }
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

            final bgUrl = currentDeco?.backgroundItem?.imageUrl;
            final clothesUrl = currentDeco?.clothesItem?.imageUrl;

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
                        const SizedBox(height: 5),
                        if (clothesUrl != null && clothesUrl.isNotEmpty)
                          Center(
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
                body: bgUrl != null && bgUrl.isNotEmpty
                    ? Container(
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
                )
                    : PageView(
                  controller: _pageController,
                  onPageChanged: (index) => setState(() => _currentIndex = index),
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
