// lib/screens/create_chat_screen.dart
import 'package:connectbeat/services/auth_service.dart';
import 'package:connectbeat/services/chat_repository_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectbeat/core/constants.dart';
import 'package:connectbeat/widgets/rounded_button.dart';
import 'package:connectbeat/widgets/bottom_bar.dart';
import 'package:connectbeat/providers/chat_repository_provider.dart';
import 'package:connectbeat/providers/current_user_provider.dart';
import 'package:connectbeat/models/chat_room.dart';
import 'package:connectbeat/services/chat_repository.dart';
import 'package:connectbeat/models/chat_message.dart';
import 'package:connectbeat/models/chat_room_event.dart';

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
                    final token = await AuthService.getToken();
                    if (token == null) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("로그인이 필요합니다.")),
                        );
                      }
                      return;
                    }

                    final userId = ref.read(currentUserProvider);
                    final chatRepo = ref.read(chatRepositoryProvider);

                    // ✅ 세션 생성 요청
                    final ChatRoom room = await chatRepo.startSession();
                    debugPrint("✅ 세션 생성 성공: ${room.chatSessionId}");

                    // ✅ 소켓 구독 시작 (메시지 + 이벤트)
                    chatRepo.subscribeMessages(room.chatSessionId).listen(
                          (ChatMessage msg) {
                        debugPrint("📩 메시지 수신: ${msg.content}");
                      },
                    );

                    if (chatRepo is ChatRepositoryImpl) {
                      chatRepo.subscribeEvents(room.chatSessionId).listen(
                            (ChatRoomEvent event) {
                          debugPrint("📡 이벤트 수신: ${event.eventType}");
                          if (event.eventType == "CONVERSATION_ENDED") {
                            if (context.mounted) {
                              Navigator.pushReplacementNamed(
                                context,
                                '/analysis', // 결과 화면 라우트
                                arguments: {'sessionId': room.chatSessionId},
                              );
                            }
                          }
                        },
                      );
                    }

                    // ✅ 채팅방 화면으로 이동
                    if (context.mounted) {
                      Navigator.pushNamed(
                        context,
                        '/chat',
                        arguments: {
                          'room': room,
                          'currentUserId': userId ?? "unknown", // ✅ null 방어
                        },
                      );
                    }
                  } catch (e) {
                    debugPrint("❌ 세션 생성 실패: $e");
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
