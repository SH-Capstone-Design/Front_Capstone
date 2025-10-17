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
    _connectSocket();
    _startTimer();
    _addUserEntranceMessage();
  }

  /// ✅ WebSocket 연결 및 이벤트 구독
  Future<void> _connectSocket() async {
    try {
      final repo = ref.read(chatRepositoryProvider);

      // ✅ STOMP 연결
      await repo.connectSocket(
        chatSessionId: widget.room.chatSessionId,
        userId: widget.currentUserId,
      );

      // ✅ 메시지 스트림
      _messageSub = repo
          .subscribeMessages(widget.room.chatSessionId)
          .listen((msg) {
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

      // ✅ 이벤트 스트림
      _eventSub =
          repo.subscribeEvents(widget.room.chatSessionId).listen((event) {
            if (_isDisposed) return;
            switch (event.eventType) {
              case "USER_JOINED":
                _addSystemMessage("상대방이 입장했습니다 💞");
                break;
              case "CONVERSATION_STARTED":
                final topic = event.payload?["topic"] ?? "주제가 선택되었습니다.";
                _addSystemMessage("🗣️ $topic");
                break;
              case "CONVERSATION_ENDED":
                _addSystemMessage("⏰ 대화가 종료되었습니다.");
                _onSessionEnd();
                break;
              default:
                break;
            }
          });
    } catch (e) {
      debugPrint("❌ 소켓 연결 실패: $e");
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

  /// ✅ 세션 종료 처리
  void _onSessionEnd() {
    if (!mounted || _isDisposed) return;
    _isDisposed = true;

    final repo = ref.read(chatRepositoryProvider);
    try {
      repo.disconnect(); // 안전하게 STOMP 종료
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
              // 🔹 AppBar
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
                    const CircleAvatar(radius: 20),
                    const SizedBox(width: 10),
                    const Text(
                      "대화 중 💬",
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
                      padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

              // 🔹 채팅 메시지
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                          gradient: isSystem
                              ? null
                              : (isMe
                              ? const LinearGradient(
                            colors: [
                              Colors.pinkAccent,
                              Colors.pinkAccent
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                              : LinearGradient(
                            colors: [Colors.grey, Colors.grey],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )),
                          color:
                          isSystem ? Colors.black.withOpacity(0.3) : null,
                          borderRadius:
                          BorderRadius.circular(isSystem ? 12 : 16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg["content"] ?? "",
                              style: TextStyle(
                                fontFamily: 'GowunBatang',
                                fontSize: isSystem ? 12 : 16,
                                fontStyle: isSystem
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                                color: isSystem
                                    ? Colors.white
                                    : (isMe
                                    ? Colors.white
                                    : Colors.black87),
                              ),
                            ),
                            if (!isSystem) ...[
                              const SizedBox(height: 4),
                              Text(
                                msg["time"] ?? "",
                                style: TextStyle(
                                  fontFamily: 'GowunBatang',
                                  fontSize: 10,
                                  color: isMe
                                      ? Colors.white70
                                      : Colors.grey[600],
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // 🔹 입력창
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  border: const Border(
                    top: BorderSide(color: Colors.grey, width: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline,
                          color: Colors.grey),
                      onPressed: () {},
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextField(
                          controller: _controller,
                          minLines: 1,
                          maxLines: 4,
                          keyboardType: TextInputType.multiline,
                          style: const TextStyle(
                            fontFamily: 'GowunBatang',
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                          decoration: const InputDecoration(
                            hintText: "메시지를 입력하세요...",
                            border: InputBorder.none,
                          ),
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
