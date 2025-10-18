import 'dart:async';
import 'package:connectbeat/models/chat_room.dart';
import 'package:connectbeat/core/constants.dart';
import 'package:connectbeat/widgets/end_chat_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_provider.dart';
import '../providers/chat_repository_provider.dart';
import 'package:connectbeat/models/chat_message.dart';
import 'package:connectbeat/models/chat_room_event.dart';
import '../providers/session_provider.dart'; // partnerId 접근용

class ChatRoomScreen extends ConsumerStatefulWidget {
  final ChatRoom room;
  final String currentUserId;

  const ChatRoomScreen({
    super.key,
    required this.room,
    required this.currentUserId,
  });

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];

  static const int _totalSeconds = 600; // 10분 타이머
  late int _remainingSeconds;
  Timer? _timer;
  StreamSubscription<ChatMessage>? _messageSub;
  StreamSubscription<ChatRoomEvent>? _eventSub;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = _totalSeconds;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeChatFlow(); // ✅ 리팩터링된 연결 순서
      _startTimer();
      _addUserEntranceMessage();
    });
  }

  /// ✅ 백엔드 ChatController 순서에 맞게 흐름 정리
  Future<void> _initializeChatFlow() async {
    try {
      final repo = ref.read(chatRepositoryProvider);
      final partnerId =
          ref.read(sessionControllerProvider.notifier).partnerId ?? "unknown";
      final chatSessionId = widget.room.chatSessionId;

      print("💬 Chat Flow Init → $chatSessionId / partner=$partnerId");

      // 1️⃣ 개인 큐 연결 (/user/queue/events)
      await repo.connectBase();
      print("✅ 개인 채널 연결 완료 (초대 이벤트 수신 대기)");

      // 2️⃣ 방 구독 (/topic/chat/room/{chatSessionId})
      await repo.subscribeRoom(chatSessionId: chatSessionId);
      print("✅ 방 구독 완료: $chatSessionId");

      // 3️⃣ 초대 전송 (A → B)
      // (이미 방을 만든 유저는 커플 상대방에게 초대 보냄)
      await repo.sendInvite(
        chatSessionId: chatSessionId,
        inviteeId: partnerId,
      );
      print("📨 초대 전송 완료 → $partnerId");

      // 4️⃣ 이벤트 리스너 (초대, join, 대화시작 등)
      _eventSub = repo.subscribeEvents(chatSessionId).listen((event) {
        if (_isDisposed) return;

        switch (event.eventType) {
          case "INVITATION":
            _addSystemMessage("📩 상대방 초대가 전송되었습니다.");
            break;
          case "USER_JOINED":
            _addSystemMessage("💞 상대방이 입장했습니다.");
            break;
          case "CONVERSATION_STARTED":
            final topic =
                event.payload?["topic"] ?? "오늘의 대화가 시작되었습니다.";
            _addSystemMessage("🗣️ $topic");
            break;
          case "CONVERSATION_ENDED":
            _addSystemMessage("⏰ 대화가 종료되었습니다.");
            _onSessionEnd();
            break;
          case "ERROR":
            final msg = event.payload?["message"] ?? "알 수 없는 오류";
            _addSystemMessage("⚠️ 오류: $msg");
            break;
          default:
            print("📬 이벤트 수신: ${event.eventType}");
        }
      });

      // 5️⃣ 메시지 스트림 리스너
      _messageSub =
          repo.subscribeMessages(chatSessionId).listen((ChatMessage msg) {
            if (_isDisposed) return;
            setState(() {
              _messages.add({
                "sender": msg.senderId == widget.currentUserId ? "me" : "other",
                "content": msg.content,
                "time": TimeOfDay.now().format(context),
              });
            });
            _scrollToBottom();
          });

      print("✅ STOMP 연결 및 이벤트 구독 완료");

    } catch (e) {
      debugPrint("❌ 채팅 초기화 실패: $e");
    }
  }

  /// ✅ 타이머 시작
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        if (mounted) {
          setState(() => _remainingSeconds = 0);
          _onSessionEnd();
        }
      } else {
        if (mounted) setState(() => _remainingSeconds--);
      }
    });
  }

  /// ✅ 세션 종료
  void _onSessionEnd() {
    if (!mounted || _isDisposed) return;
    _isDisposed = true;

    final repo = ref.read(chatRepositoryProvider);
    try {
      repo.disconnect();
    } catch (e) {
      debugPrint("⚠️ disconnect 중 오류: $e");
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("⏰ 채팅 세션이 종료되었습니다.")),
    );

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  /// ✅ 메시지 전송
  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final repo = ref.read(chatRepositoryProvider);
    repo.sendMessage(
      chatSessionId: widget.room.chatSessionId,
      senderId: widget.currentUserId,
      content: text,
    );

    setState(() {
      _messages.add({
        "sender": "me",
        "content": text,
        "time": TimeOfDay.now().format(context),
      });
    });
    _controller.clear();
    _scrollToBottom();
  }

  void _addSystemMessage(String text) {
    if (_isDisposed) return;
    setState(() {
      _messages.add({
        "sender": "system",
        "content": text,
        "time": TimeOfDay.now().format(context),
      });
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 60,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _addUserEntranceMessage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userState = ref.read(userProvider);
      String nickname = widget.currentUserId;
      userState.maybeWhen(
        data: (user) {
          nickname = user['nickname'] ?? widget.currentUserId;
        },
        orElse: () {},
      );
      _addSystemMessage("$nickname님이 입장했습니다 💬");
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    _messageSub?.cancel();
    _eventSub?.cancel();

    try {
      final repo = ref.read(chatRepositoryProvider);
      repo.disconnect();
    } catch (e) {
      debugPrint("⚠️ dispose 중 disconnect 실패: $e");
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppConstants.backgroundPath),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 상단 바
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final shouldEnd = await showDialog<bool>(
                          context: context,
                          builder: (_) => const EndChatDialog(),
                        );
                        if (shouldEnd == true) _onSessionEnd();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.exit_to_app,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "10분 대화 💬",
                      style: TextStyle(
                        fontFamily: 'GowunBatang',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            offset: Offset(1, 1),
                            blurRadius: 2,
                          )
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _formatTime(_remainingSeconds),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 메시지 영역
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final sender = msg["sender"];
                    final isMe = sender == "me";
                    final isSystem = sender == "system";

                    return Align(
                      alignment: isSystem
                          ? Alignment.center
                          : (isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: isSystem
                              ? Colors.black.withOpacity(0.3)
                              : (isMe
                              ? Colors.pinkAccent
                              : Colors.grey[300]),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          msg["content"] ?? "",
                          style: TextStyle(
                            fontFamily: 'GowunBatang',
                            fontSize: isSystem ? 12 : 16,
                            fontStyle:
                            isSystem ? FontStyle.italic : FontStyle.normal,
                            color: isSystem
                                ? Colors.white
                                : (isMe ? Colors.white : Colors.black87),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // 입력창
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                color: Colors.white.withOpacity(0.9),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(fontFamily: 'GowunBatang'),
                        decoration: const InputDecoration(
                          hintText: "메시지를 입력하세요...",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.black),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
