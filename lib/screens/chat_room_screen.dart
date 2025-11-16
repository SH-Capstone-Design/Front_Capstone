import 'dart:async';
import 'dart:io';
import 'package:connectbeat/models/chat_room.dart';
import 'package:connectbeat/models/chat_message.dart';
import 'package:connectbeat/models/chat_room_event.dart';
import 'package:connectbeat/core/constants.dart';
import 'package:connectbeat/widgets/end_chat_dialog.dart';
import 'package:connectbeat/widgets/reportloading_dialog.dart';
import 'package:connectbeat/widgets/waiting_dialog.dart';
import 'package:connectbeat/widgets/message_input_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_provider.dart';
import '../providers/chat_repository_provider.dart';
import 'package:connectbeat/services/chat_report_service.dart';
import '../providers/couple_provider.dart';

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
  final Set<String> _messageCache = {};

  static const int _totalSeconds = 600;
  late int _remainingSeconds;
  Timer? _timer;

  StreamSubscription<ChatMessage>? _messageSub;
  StreamSubscription<ChatRoomEvent>? _eventSub;

  bool _isDisposed = false;
  bool _chatEnded = false;
  bool _isEnding = false;
  bool _chatStarted = false;
  bool _isWaitingDialogShown = false;
  bool _isManualClosing = false;
  bool _showEmojiPicker = false;

  static const double _messageInputBarHeight = 60.0;
  static const double _emojiPickerHeight = 250.0;

  double get _bottomInset {
    // 이모티콘 열리면 높이만큼 패딩 추가, 키보드 올라오면 키보드 높이 반영
    return (_showEmojiPicker ? _emojiPickerHeight : 0) + MediaQuery.of(context).viewInsets.bottom + _messageInputBarHeight;
  }

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

    if (widget.autoStart) {
      _showWaitingDialog();
    } else {
      await repo.sendJoin(chatSessionId: chatSessionId);
    }

    _messageSub = repo.subscribeMessages(chatSessionId).listen((msg) {
      if (_isDisposed) return;
      final key = "${msg.senderId}-${msg.content}";
      if (_messageCache.contains(key)) return;
      _messageCache.add(key);

      setState(() => _messages.add(msg));
      _scrollToBottom();
    });

    _eventSub = repo.subscribeEvents(chatSessionId).listen((event) async {
      if (_isDisposed) return;
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
        case "INVITATION":
          if (_isWaitingDialogShown) _dismissWaitingDialog();
          _showWaitingDialog();
          break;
        case "INVITATION_CANCELED":
          _dismissWaitingDialog();
          _addSystemMessage("🚫 상대방이 초대를 취소했습니다.");
          if (!mounted) return;
          Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
          break;
        case "CONVERSATION_STARTED":
          if (!_chatStarted) {
            _chatStarted = true;
            _addSystemMessage("🗣️ 대화가 시작되었습니다! 10분 타이머 시작");
            _startTimer();
          }
          break;
        case "CONVERSATION_ENDED":
          await _handleEndSession(isRemote: true);
          break;
        case "ERROR":
          final msg = event.payload?["message"] ?? "알 수 없는 오류";
          _addSystemMessage("⚠️ 오류: $msg");
          break;
      }
    });
  }

  void _showWaitingDialog() {
    if (_isWaitingDialogShown || !mounted) return;
    _isWaitingDialogShown = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const WaitingDialog(
        message: "상대방이 입장할 때까지 기다려주세요...",
      ),
    ).then((_) => _isWaitingDialogShown = false);
  }

  void _dismissWaitingDialog() {
    if (!_isWaitingDialogShown || !mounted) return;
    _isWaitingDialogShown = false;
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        _timer = null;
        if (mounted) setState(() => _remainingSeconds = 0);
        _handleEndSession(navigateToResult: true);
      } else {
        if (mounted) setState(() => _remainingSeconds--);
      }
    });
  }

  Future<void> _handleEndSession({bool navigateToResult = true, bool isRemote = false}) async {
    if (_isEnding) return;
    _isEnding = true;

    if (!isRemote) _isManualClosing = true;

    _addSystemMessage(isRemote
        ? "⏰ 상대방이 채팅을 종료했습니다."
        : "⏰ 채팅 세션 종료 중...");

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (_) => const ReportLoadingOverlay(),
    );

    try {
      final repo = ref.read(chatRepositoryProvider);
      if (!isRemote) await repo.sendEndChat(chatSessionId: widget.room.chatSessionId);
      if (!_isManualClosing || isRemote) await repo.closeSession(widget.room.chatSessionId);

      Map<String, dynamic>? report;
      for (int i = 0; i < 60; i++) {
        report = await ChatReportService.getReportBySession(widget.room.chatSessionId);
        if (report != null && (report['gptFeedback']?.toString().isNotEmpty ?? false)) break;
        await Future.delayed(const Duration(seconds: 1));
      }

      report ??= {'gptFeedback': '리포트를 불러오지 못했습니다.'};

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      if (navigateToResult && mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/emotion-result',
          arguments: widget.room.chatSessionId,
        );
      }
    } catch (e) {
      debugPrint("❌ 채팅 종료 오류: $e");
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    } finally {
      _chatEnded = true;
    }
  }

  Future<void> _sendMessage(String text) async {
    if (!_chatStarted) return;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final key = "${widget.currentUserId}-$trimmed";
    if (_messageCache.contains(key)) return;
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
        type: "TEXT",
        nickname: "나",
        profileImage: null,
        sentAt: DateTime.now(),
      ));
    });

    _scrollToBottom();
  }

  Future<void> _sendImageMessage(File imageFile) async {
    try {
      final repo = ref.read(chatRepositoryProvider);
      await repo.sendImageMessage(
        chatSessionId: widget.room.chatSessionId,
        senderId: widget.currentUserId,
        imageFile: imageFile,
      );
    } catch (e) {
      debugPrint('⚠️ 이미지 메시지 전송 실패: $e');
    }
  }

  Future<void> _sendEmoticonMessage(String emoticonUrl) async {
    try {
      final repo = ref.read(chatRepositoryProvider);
      await repo.sendEmoticonMessage(
        chatSessionId: widget.room.chatSessionId,
        senderId: widget.currentUserId,
        emoticonUrl: emoticonUrl,
      );
    } catch (e) {
      debugPrint('⚠️ 이모티콘 메시지 전송 실패: $e');
    }
  }

  void _addSystemMessage(String text) {
    if (_isDisposed) return;
    setState(() {
      _messages.add(ChatMessage(
        chatSessionId: widget.room.chatSessionId,
        senderId: "system",
        content: text,
        type: "SYSTEM",
        nickname: "system",
        profileImage: null,
        sentAt: DateTime.now(),
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
        data: (user) => nickname = user['nickname'] ?? widget.currentUserId,
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
    _dismissWaitingDialog();
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
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: AnimatedPadding(
                    duration: const Duration(milliseconds: 250),
                    padding: EdgeInsets.only(bottom: _bottomInset),
                    child: _buildMessageList(ref.watch(coupleStatusProvider)),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                top: false,
                child: MessageInputBar(
                  onSend: _sendMessage,
                  onSendImage: _sendImageMessage,
                  onSendEmoticon: _sendEmoticonMessage,
                  showEmojiPicker: _showEmojiPicker,
                  onEmojiPickerToggle: (visible) {
                    setState(() => _showEmojiPicker = visible);
                    if (visible) FocusScope.of(context).unfocus();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              if (_isEnding) return;
              final shouldEnd = await showDialog<bool>(
                context: context,
                builder: (_) => EndChatDialog(chatSessionId: widget.room.chatSessionId),
              );
              if (shouldEnd == true) await _handleEndSession(navigateToResult: true);
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.exit_to_app, color: Colors.black, size: 22),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            "10분 대화 💬",
            style: TextStyle(
              fontFamily: 'GowunBatang',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              shadows: [Shadow(color: Colors.black45, offset: Offset(1, 1), blurRadius: 2)],
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
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(AsyncValue<Map<String, dynamic>?> coupleAsync) {
    return coupleAsync.when(
      data: (coupleData) {
        final partnerNickname = coupleData?['partnerNickname'] ?? "상대방";
        final partnerProfile = coupleData?['partnerProfileImage'];
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: _messages.length,
          itemBuilder: (context, index) {
            final msg = _messages[index];
            final previousMsg = index > 0 ? _messages[index - 1] : null;
            final isMe = msg.senderId == widget.currentUserId;
            final isSystem = msg.senderId == "system";
            final showProfile = index == 0 || _messages[index - 1].senderId != msg.senderId;

            if (isSystem) return _buildSystemMessage(msg);

            return _buildChatMessage(
                msg, isMe, showProfile, partnerNickname, partnerProfile, previousMsg);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, st) {
        debugPrint("❌ coupleStatusProvider 오류: $err");
        return const Center(child: Text("상대방 정보를 불러오지 못했습니다."));
      },
    );
  }

  Widget _buildSystemMessage(ChatMessage msg) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          msg.content,
          style: const TextStyle(
            fontFamily: 'GowunBatang',
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildChatMessage(
      ChatMessage msg,
      bool isMe,
      bool showProfile,
      String partnerNickname,
      String? partnerProfile,
      ChatMessage? previousMsg,
      ) {
    final bool isMedia = msg.type == "IMAGE" || msg.type == "EMOTICON";

    final int index = _messages.indexOf(msg);
    ChatMessage? nextMsg = index < _messages.length - 1 ? _messages[index + 1] : null;

    bool showTime = true;
    if (nextMsg != null && msg.sentAt != null && nextMsg.sentAt != null) {
      if (msg.sentAt!.hour == nextMsg.sentAt!.hour &&
          msg.sentAt!.minute == nextMsg.sentAt!.minute) {
        showTime = false;
      }
    }

    if (isMedia && nextMsg != null) {
      if (nextMsg.sentAt != null &&
          msg.sentAt != null &&
          msg.sentAt!.hour == nextMsg.sentAt!.hour &&
          msg.sentAt!.minute == nextMsg.sentAt!.minute) {
        showTime = false;
      }
    }

    Widget contentWidget;
    if (msg.type == "TEXT") {
      contentWidget = Text(
        msg.content,
        style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 16),
      );
    } else if (msg.type == "IMAGE") {
      contentWidget = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(msg.content, width: 120, height: 120, fit: BoxFit.cover),
      );
    } else if (msg.type == "EMOTICON") {
      contentWidget = Image.network(msg.content, width: 90, height: 90, fit: BoxFit.contain);
    } else {
      contentWidget = Text(msg.content);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe && showProfile) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: partnerProfile != null ? NetworkImage(partnerProfile) : null,
              child: partnerProfile == null ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 8),
          ] else if (!isMe)
            const SizedBox(width: 40),
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe && showProfile)
                  Text(partnerNickname,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: isMedia
                      ? EdgeInsets.zero
                      : const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: isMedia
                      ? null
                      : BoxDecoration(
                    color: isMe ? const Color(0xFFEC9FFF) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: contentWidget,
                ),
                if (showTime && msg.sentAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      "${msg.sentAt!.hour.toString().padLeft(2, '0')}:${msg.sentAt!.minute.toString().padLeft(2, '0')}",
                      style: const TextStyle(fontSize: 11, color: Colors.black45),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
