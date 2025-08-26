// lib/screens/chat_room_screen.dart
// 10분 세션형 채팅 화면: 상단 타이머, 본문 메시지 리스트, 하단 입력바
// - Riverpod: 메시지 구독/전송, 세션 종료 시 closeRoom 호출
// - TODO(auth): currentUserId를 실제 로그인 사용자 ID로 교체

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectbeat/services/chat_repository.dart';
import 'package:connectbeat/providers/chat_messages_controller.dart';
import 'package:connectbeat/providers/chat_repository_provider.dart';
import 'package:connectbeat/widgets/message_bubble.dart';
import 'package:connectbeat/widgets/message_input_bar.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  const ChatRoomScreen({
    super.key,
    required this.room,
    required this.currentUserId,
  });

  /// 생성된 채팅방(세션)
  final ChatRoom room;
  /// 로그인 사용자 ID (임시 고정값 사용 중). TODO(auth): Provider 연동
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

    // 메시지 구독 시작
    ref.read(chatMessagesProvider.notifier).start(widget.room.id);

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
    // 세션 종료 처리 → 분석 파이프라인 트리거
    await ref.read(chatRepositoryProvider).closeRoom(widget.room.id);

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('세션 종료'),
        content: const Text('10분 대화가 종료되었어요. 분석 화면으로 이동합니다.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    // TODO(analysis): 분석 결과 화면 라우팅. 당장은 이전 화면으로 복귀
    Navigator.of(context).pop();
  }

  String _formatRemain(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _send(String text) async {
    // 현재 로그인 사용자 ID로 전송
    await ref.read(chatRepositoryProvider).sendMessage(
      roomId: widget.room.id,
      senderId: widget.currentUserId,
      text: text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              widget.room.topicName ?? '채팅',
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
            ),
            Text(
              '남은 시간 ${_formatRemain(_remain)}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
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
            onSend: (t) async => _ended ? null : _send(t),
            enabled: !_ended,
          ),
        ],
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
          Icon(Icons.chat_bubble_outline, size: 48, color: Colors.black26),
          SizedBox(height: 8),
          Text('대화를 시작해 보세요', style: TextStyle(color: Colors.black45)),
        ],
      ),
    );
  }
}