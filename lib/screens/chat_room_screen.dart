// lib/screens/chat_room_screen.dart
import 'dart:async';
import 'package:connectbeat/models/chat_room.dart';
import 'package:connectbeat/models/chat_message.dart';
import 'package:connectbeat/models/chat_room_event.dart';
import 'package:connectbeat/core/constants.dart';
import 'package:connectbeat/widgets/end_chat_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_provider.dart';
import '../providers/session_provider.dart';
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
  final Set<String> _messageCache = {}; // 중복 체크용

  static const int _totalSeconds = 600;
  late int _remainingSeconds;
  Timer? _timer;
  StreamSubscription<ChatMessage>? _messageSub;
  StreamSubscription<ChatRoomEvent>? _eventSub;
  bool _isDisposed = false;

  bool _partnerJoined = false;
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

    // 메시지 구독
    _messageSub = repo.subscribeMessages(chatSessionId).listen((msg) {
      if (_isDisposed) return;

      final key = "${msg.senderId}-${msg.content}";
      if (_messageCache.contains(key)) return; // 중복 방지
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

    // 이벤트 구독
    _eventSub = repo.subscribeEvents(chatSessionId).listen((event) {
      if (_isDisposed) return;

      switch (event.eventType) {
        case "CONVERSATION_STARTED":
        // 상대방이 채팅 수락 후 시작 신호를 보내야 실행
          _partnerJoined = true;
          _tryStartChat();
          break;

        case "USER_JOINED":
        // 단순 입장 알림만
          if (event.payload?['userId'] != widget.currentUserId) {
            _addSystemMessage("💞 상대방이 채팅방에 입장했습니다.");
          }
          break;

        case "CONVERSATION_ENDED":
          _addSystemMessage("⏰ 대화가 종료되었습니다.");
          _onSessionEnd();
          break;

        case "ERROR":
          final msg = event.payload?["message"] ?? "알 수 없는 오류";
          _addSystemMessage("⚠️ 오류: $msg");
          break;
      }
    });

    if (!widget.autoStart) {
      await repo.sendJoin(chatSessionId: chatSessionId);
      _partnerJoined = true;
      _tryStartChat();
    }
  }

  void _tryStartChat() {
    if (_chatStarted) return;

    // 둘 다 입장했을 때만 시작
    if (_partnerJoined && widget.autoStart) {
      _chatStarted = true;
      _addSystemMessage("🗣️ 대화가 시작되었습니다! 10분 타이머 작동 중.");
      _startTimer();
    } else if (_partnerJoined && !widget.autoStart) {
      _chatStarted = true;
      _addSystemMessage("🗣️ 대화가 시작되었습니다! 10분 타이머 작동 중.");
      _startTimer(); // B도 타이머 시작
    }
  }

  void _startTimer() {
    if (_timer != null) return; // 이미 타이머 실행 중이면 중복 방지

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        _timer = null;
        if (mounted) {
          setState(() => _remainingSeconds = 0);
          _onSessionEnd(navigateToResult: true);
        }
      } else {
        if (mounted) setState(() => _remainingSeconds--);
      }
    });
  }

  void _onSessionEnd({bool navigateToResult = false}) {
    if (!mounted || _isDisposed) return;
    _isDisposed = true;

    try {
      ref.read(chatRepositoryProvider).disconnect();
    } catch (e) {
      debugPrint("⚠️ disconnect 중 오류: $e");
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("⏰ 채팅 세션이 종료되었습니다.")),
    );

    if (navigateToResult) {
      Navigator.pushReplacementNamed(context, '/emotion-result');
      return;
    }

    if (Navigator.canPop(context)) Navigator.pop(context);
  }

  void _sendMessage() {
    if (!_chatStarted) return;

    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final key = "${widget.currentUserId}-$text";
    _messageCache.add(key); // 로컬 메시지 중복 등록 방지

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
                          : (isMe ? Alignment.centerRight : Alignment.centerLeft),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
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
                        enabled: _chatStarted,
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
                      onPressed: _chatStarted ? _sendMessage : null,
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
