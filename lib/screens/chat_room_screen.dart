import 'dart:async';
import 'package:connectbeat/models/chat_room.dart';
import 'package:connectbeat/models/chat_message.dart';
import 'package:connectbeat/models/chat_room_event.dart';
import 'package:connectbeat/core/constants.dart';
import 'package:connectbeat/widgets/end_chat_dialog.dart';
import 'package:connectbeat/widgets/waiting_dialog.dart';
import 'package:connectbeat/widgets/message_bubble.dart';
import 'package:connectbeat/widgets/message_input_bar.dart';
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
  final List<ChatMessage> _messages = [];
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

    // B가 입장할 때만 join 전송
    if (!widget.autoStart) {
      await repo.sendJoin(chatSessionId: chatSessionId);
    } else {
      _showWaitingDialog();
    }

    // 메시지 수신 스트림
    _messageSub = repo.subscribeMessages(chatSessionId).listen((msg) {
      if (_isDisposed) return;
      final key = "${msg.senderId}-${msg.content}";
      if (_messageCache.contains(key)) return;
      _messageCache.add(key);

      setState(() => _messages.add(msg));
      _scrollToBottom();
    });

    // 이벤트 수신 스트림
    _eventSub = repo.subscribeEvents(chatSessionId).listen((event) async {
      if (_isDisposed) return;
      debugPrint("🔥 이벤트 수신: ${event.eventType}");

      switch (event.eventType) {
        case "USER_JOINED":
          _dismissWaitingDialog();
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

  void _showWaitingDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const WaitingDialog(
          message: "상대방이 입장할 때까지 기다려주세요...",
        ),
      );
    });
  }

  void _dismissWaitingDialog() {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
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
      await repo.sendEndChat(chatSessionId: widget.room.chatSessionId);

      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted && navigateToResult) {
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

  Future<void> _sendMessage(String text) async {
    if (!_chatStarted || _chatEnded) return;

    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final key = "${widget.currentUserId}-$trimmed";
    _messageCache.add(key);

    await ref.read(chatRepositoryProvider).sendMessage(
      chatSessionId: widget.room.chatSessionId,
      senderId: widget.currentUserId,
      content: trimmed,
    );

    setState(() {
      _messages.add(ChatMessage(
        chatSessionId: widget.room.chatSessionId,
        senderId: widget.currentUserId,
        content: trimmed,
      ));
    });

    _scrollToBottom();
  }

  void _addSystemMessage(String text) {
    if (_isDisposed) return;
    setState(() {
      _messages.add(ChatMessage(
        chatSessionId: widget.room.chatSessionId,
        senderId: "system",
        content: text,
      ));
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
                    final isMe = msg.senderId == widget.currentUserId;
                    final isSystem = msg.senderId == "system";

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
                          msg.content,
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
              MessageInputBar(
                onSend: _sendMessage,
                enabled: _chatStarted && !_chatEnded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
