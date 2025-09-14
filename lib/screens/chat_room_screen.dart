// lib/screens/chat_room_screen.dart
import 'dart:async';
import 'package:connectbeat/screens/analysis_result_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectbeat/services/chat_repository.dart';
import 'package:connectbeat/providers/chat_messages_controller.dart';
import 'package:connectbeat/providers/chat_repository_provider.dart';
import 'package:connectbeat/widgets/message_bubble.dart';
import 'package:connectbeat/widgets/message_input_bar.dart';
import 'package:connectbeat/widgets/end_chat_dialog.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  const ChatRoomScreen({
    super.key,
    required this.room,
    required this.currentUserId,
  });

  /// 생성된 채팅 세션
  final ChatRoom room;

  /// 로그인 사용자 ID
  final String currentUserId;

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  static const int _sessionSeconds = 600; // 10분
  late int _remain = _sessionSeconds;
  Timer? _timer;
  final ScrollController _scroll = ScrollController();
  bool _ended = false;

  @override
  void initState() {
    super.initState();

    // ✅ 세션 ID 기반 메시지 구독 시작
    ref.read(chatMessagesProvider.notifier).start(widget.room.chatSessionId);

    // 새 메시지 들어오면 하단으로 스크롤
    ref.listen<List<ChatMessage>>(chatMessagesProvider, (prev, next) {
      if (!mounted || next.isEmpty) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent + 80,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
          );
        }
      });
    });

    // 세션 타이머 시작
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) return;
      setState(() => _remain--);
      if (_remain <= 0) {
        timer.cancel();
        await _handleSessionEnd();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _handleSessionEnd() async {
    if (_ended) return;
    _ended = true;

    // ✅ 세션 종료 처리
    await ref
        .read(chatRepositoryProvider)
        .closeSession(widget.room.chatSessionId);

    if (!mounted) return;
    // 10분이 지나면 자동으로 결과 화면으로 이동
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AnalysisResultScreen()),
    );
  }

  /// 채팅방 나가기 시도 시 호출 (뒤로가기 버튼만 처리)
  Future<bool> _onWillPop() async {
    if (_ended) return true; // 이미 종료된 상태면 그냥 나감

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (_) => const EndChatDialog(),
    );

    if (shouldExit == true && mounted) {
      // ✅ 사용자가 "예"를 누른 경우 → 세션 종료 + 결과 화면 이동
      await ref
          .read(chatRepositoryProvider)
          .closeSession(widget.room.chatSessionId);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AnalysisResultScreen()),
      );
      return true;
    }
    return false; // "아니오" → 채팅방 잔류
  }

  String _formatRemain(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _send(String content) async {
    if (_ended) return;
    await ref.read(chatRepositoryProvider).sendMessage(
      chatSessionId: widget.room.chatSessionId,
      senderId: widget.currentUserId,
      content: content,
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider);

    return WillPopScope(
      onWillPop: _onWillPop, // ← 뒤로가기 버튼 제어
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF8FC),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                widget.room.chatSessionId,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '남은 시간 ${_formatRemain(_remain)}',
                style:
                const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
          iconTheme: const IconThemeData(color: Colors.black87),
        ),
        body: Column(
          children: <Widget>[
            Expanded(
              child: messages.isEmpty
                  ? const _EmptyState()
                  : ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: messages.length,
                itemBuilder: (context, i) {
                  final m = messages[i];
                  final isMine = m.senderId == widget.currentUserId;
                  return MessageBubble(message: m, isMine: isMine);
                },
              ),
            ),
            MessageInputBar(
              onSend: (t) async => _send(t),
              enabled: !_ended,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const <Widget>[
          Icon(Icons.chat_bubble_outline,
              size: 48, color: Colors.black26),
          SizedBox(height: 8),
          Text('대화를 시작해 보세요',
              style: TextStyle(color: Colors.black45)),
        ],
      ),
    );
  }
}
