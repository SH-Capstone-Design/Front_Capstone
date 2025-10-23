import 'dart:async';
import 'package:connectbeat/models/chat_room.dart';
import 'package:connectbeat/models/chat_message.dart';
import 'package:connectbeat/models/chat_room_event.dart';
import 'package:connectbeat/core/constants.dart';
import 'package:connectbeat/widgets/end_chat_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_provider.dart';
import '../providers/chat_repository_provider.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  final ChatRoom room;
  final String currentUserId;
  final bool autoStart;

  const ChatRoomScreen({
    super.key,
    required this.room,
    required this.currentUserId,
    this.autoStart = true,
  });

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  final Set<String> _messageCache = {}; // 중복 메시지 방지용

  static const int _totalSeconds = 600;
  late int _remainingSeconds;
  Timer? _timer;

  StreamSubscription<ChatMessage>? _messageSub;
  StreamSubscription<ChatRoomEvent>? _eventSub;

  bool _isDisposed = false;
  bool _chatEnded = false;
  bool _isEnding = false;
  bool _chatStarted = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = _totalSeconds;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeChatFlow();
      _addUserEntranceMessage();
    });
  }

  Future<void> _initializeChatFlow() async {
    final repo = ref.read(chatRepositoryProvider);
    final chatSessionId = widget.room.chatSessionId;

    await repo.connectBase();
    await repo.subscribeRoom(chatSessionId: chatSessionId);

    // B가 입장할 때만 join 전송
    if (!widget.autoStart) {
      await repo.sendJoin(chatSessionId: chatSessionId);
    }

    // 메시지 수신 스트림
    _messageSub = repo.subscribeMessages(chatSessionId).listen((msg) {
      if (_isDisposed) return;

      final key = "${msg.senderId}-${msg.content}";
      if (_messageCache.contains(key)) return;
      _messageCache.add(key);

      setState(() {
        _messages.add({
          "sender": msg.senderId == widget.currentUserId ? "me" : "partner",
          "content": msg.content,
          "time": TimeOfDay.now().format(context),
        });
      });
      _scrollToBottom();
    });

    // 이벤트 수신 스트림
    _eventSub = repo.subscribeEvents(chatSessionId).listen((event) async {
      if (_isDisposed) return;
      debugPrint("🔥 이벤트 수신: ${event.eventType}");

      switch (event.eventType) {
        case "USER_JOINED":
          if (event.payload?['userId'] != widget.currentUserId) {
            _addSystemMessage("💞 상대방이 채팅방에 입장했습니다.");
            if (!_chatStarted) {
              _chatStarted = true;
              _addSystemMessage("🗣️ 대화가 시작되었습니다! 10분 타이머 시작");
              _startTimer();
            }
          }
          break;

        case "CONVERSATION_STARTED":
          if (!_chatStarted && !widget.autoStart) {
            _chatStarted = true;
            _addSystemMessage("🗣️ 대화가 시작되었습니다! 10분 타이머 시작");
            _startTimer();
          }
          break;

        case "CONVERSATION_ENDED":
          debugPrint("📩 CONVERSATION_ENDED 수신됨 — 상대방 종료 처리");
          await _handleRemoteEnd();
          break;

        case "ERROR":
          final msg = event.payload?["message"] ?? "알 수 없는 오류";
          _addSystemMessage("⚠️ 오류: $msg");
          break;
      }
    });
  }

  void _startTimer() {
    if (_timer != null) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        _timer = null;
        if (mounted) setState(() => _remainingSeconds = 0);
        _handleTimerEnd();
      } else {
        if (mounted) setState(() => _remainingSeconds--);
      }
    });
  }

  Future<void> _handleTimerEnd() async {
    if (!_chatEnded) {
      _addSystemMessage("⏰ 시간이 다 되어 채팅이 종료됩니다.");
      await _onSessionEnd(navigateToResult: true);
    }
  }

  Future<void> _onSessionEnd({bool navigateToResult = false}) async {
    if (_isEnding) return;
    _isEnding = true;
    _chatEnded = true;
    _timer?.cancel();

    _addSystemMessage("⏰ 채팅 세션 종료 중...");

    try {
      final repo = ref.read(chatRepositoryProvider);

      // 1️⃣ STOMP 종료 이벤트 전송
      await repo.sendEndChat(chatSessionId: widget.room.chatSessionId);

      // 2️⃣ broadcast가 먼저 나가도록 딜레이
      await Future.delayed(const Duration(milliseconds: 300));

      // 3️⃣ REST API는 내가 직접 종료할 때만 호출
      // (상대방 이벤트에서는 호출 안 함)
      // await repo.api.closeSession(widget.room.chatSessionId);

      // 4️⃣ EmotionResult로 이동
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 300));
        Navigator.pushReplacementNamed(
          context,
          '/emotion-result',
          arguments: widget.room.chatSessionId,
        );
      }
    } catch (e) {
      debugPrint("❌ 채팅 종료 오류: $e");
    }
  }

  Future<void> _handleRemoteEnd() async {
    if (_isEnding) return;
    _isEnding = true;
    _chatEnded = true;
    _timer?.cancel();

    _addSystemMessage("⏰ 상대방이 채팅을 종료했습니다.");

    try {
      // REST 호출 제거 — 이미 서버에서 종료 처리됨
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/emotion-result',
          arguments: widget.room.chatSessionId,
        );
      }
    } catch (e) {
      debugPrint("❌ 상대방 종료 처리 오류: $e");
    }
  }

  void _sendMessage() {
    if (!_chatStarted || _chatEnded) return;

    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final key = "${widget.currentUserId}-$text";
    _messageCache.add(key);

    ref.read(chatRepositoryProvider).sendMessage(
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
      ref.read(chatRepositoryProvider).disconnect();
    } catch (e) {
      debugPrint("⚠️ dispose 중 disconnect 실패: $e");
    }
    super.dispose();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
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
                        if (_chatEnded || _isEnding) return;

                        final shouldEnd = await showDialog<bool>(
                          context: context,
                          builder: (_) => EndChatDialog(
                            chatSessionId: widget.room.chatSessionId,
                          ),
                        );

                        if (shouldEnd == true) {
                          await _onSessionEnd(navigateToResult: true);
                        }
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

              // 메시지 리스트
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
                          : (isMe ? Alignment.centerRight : Alignment.centerLeft),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: isSystem
                              ? Colors.black.withOpacity(0.3)
                              : (isMe ? Colors.pinkAccent : Colors.grey[300]),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          msg["content"] ?? "",
                          style: TextStyle(
                            fontFamily: 'GowunBatang',
                            fontSize: isSystem ? 12 : 16,
                            fontStyle: isSystem ? FontStyle.italic : FontStyle.normal,
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
                        enabled: _chatStarted && !_chatEnded,
                        decoration: InputDecoration(
                          hintText: _chatStarted
                              ? "메시지를 입력하세요..."
                              : "상대방 입장 대기 중...",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.black),
                      onPressed: _chatStarted && !_chatEnded ? _sendMessage : null,
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
