import 'package:connectbeat/providers/chat_repository_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectbeat/widgets/rounded_button.dart';
import 'package:connectbeat/widgets/bottom_bar.dart';
import 'package:connectbeat/services/chat_repository.dart'; // ChatRoom 참조

class TopicSelectScreen extends ConsumerStatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onNavTap;

  const TopicSelectScreen({
    super.key,
    this.selectedIndex = 0,
    this.onNavTap = _defaultOnTap,
  });

  static void _defaultOnTap(int idx) {}

  @override
  ConsumerState<TopicSelectScreen> createState() => _TopicSelectScreenState();
}

class _TopicSelectScreenState extends ConsumerState<TopicSelectScreen> {
  String? _selectedTopic;

  final List<String> _topics = [
    "연애",
    "학업",
    "취미",
    "여행",
    "기타",
  ];

  void _startChat() async {
    if (_selectedTopic == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("대화 주제를 선택하세요")),
      );
      return;
    }

    try {
      // ✅ 실제 세션 생성 API 호출
      final chatRepo = ref.read(chatRepositoryProvider);
      final ChatRoom room = await chatRepo.startSession();

      if (!mounted) return;

      Navigator.pushNamed(
        context,
        '/chat',
        arguments: {
          'room': room,
          'currentUserId': 'test-user-123', // TODO: 실제 로그인 ID로 교체
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("채팅방 생성 실패: $e")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8FC),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: size.height * 0.06),
            const Text(
              "대화 주제 카테고리",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: DropdownButtonFormField<String>(
                value: _selectedTopic,
                items: _topics
                    .map((topic) => DropdownMenuItem(
                  value: topic,
                  child: Text(topic),
                ))
                    .toList(),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                hint: const Text("주제를 선택하세요"),
                onChanged: (val) => setState(() => _selectedTopic = val),
              ),
            ),
            const Spacer(flex: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: RoundedButton(
                text: "대화 시작",
                onPressed: _startChat,
              ),
            ),
            const Spacer(flex: 3),
          ],
        ),
      ),
      bottomNavigationBar: BottomBar(
        currentIndex: widget.selectedIndex,
        onTap: widget.onNavTap,
      ),
    );
  }
}
