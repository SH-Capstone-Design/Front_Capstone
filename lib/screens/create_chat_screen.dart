// lib/screens/create_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectbeat/core/constants.dart';
import 'package:connectbeat/widgets/rounded_button.dart';
import 'package:connectbeat/widgets/bottom_bar.dart';
import 'package:connectbeat/providers/chat_repository_provider.dart';
import 'package:connectbeat/services/chat_repository.dart';
import 'package:connectbeat/providers/current_user_provider.dart';

class CreateChatScreen extends ConsumerWidget {
  final int selectedIndex;
  final ValueChanged<int> onNavTap;

  const CreateChatScreen({
    super.key,
    this.selectedIndex = 0,
    this.onNavTap = _defaultOnTap,
  });

  static void _defaultOnTap(int idx) {}

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8FC),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: size.height * 0.06),
            Center(
              child: Image.asset(
                AppConstants.logoPath,
                height: 50,
                fit: BoxFit.contain,
              ),
            ),
            const Spacer(flex: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: RoundedButton(
                text: "채팅방 생성",
                onPressed: () async {
                  try {
                    final userId = ref.read(currentUserProvider);
                    if (userId == null) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("로그인이 필요합니다.")),
                        );
                      }
                      return;
                    }

                    // ✅ 실제 서버에 채팅 세션 생성 요청
                    final chatRepo = ref.read(chatRepositoryProvider);
                    final ChatRoom room = await chatRepo.startSession();

                    if (context.mounted) {
                      Navigator.pushNamed(
                        context,
                        '/chat',
                        arguments: {
                          'room': room,
                          'currentUserId': userId, // ✅ 로그인된 유저 ID
                        },
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('채팅방 생성 실패: $e')),
                      );
                    }
                  }
                },
              ),
            ),
            const Spacer(flex: 3),
          ],
        ),
      ),
      bottomNavigationBar: BottomBar(
        currentIndex: selectedIndex,
        onTap: onNavTap,
      ),
    );
  }
}
