// // lib/screens/topic_select_screen.dart
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:connectbeat/providers/topic_provider.dart';
// import 'package:connectbeat/models/topic.dart';
// import 'package:connectbeat/providers/chat_repository_provider.dart';
// import 'package:connectbeat/providers/current_user_provider.dart';
// import 'package:connectbeat/services/auth_service.dart';
// import 'package:connectbeat/models/chat_room.dart';
// import 'package:connectbeat/models/chat_message.dart';
// import 'package:connectbeat/models/chat_room_event.dart';
// import 'package:connectbeat/services/chat_repository_impl.dart';
//
// class TopicSelectScreen extends ConsumerWidget {
//   const TopicSelectScreen({super.key});
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final categoriesAsync = ref.watch(topicCategoriesProvider);
//     final selectedCategory = ref.watch(selectedCategoryProvider);
//
//     return Scaffold(
//       backgroundColor: const Color(0xFFFFF8FC),
//       appBar: AppBar(
//         title: const Text(
//           '대화 주제 선택',
//           style: TextStyle(fontFamily: 'GowunBatang'),
//         ),
//         backgroundColor: const Color(0xFFFFF8FC),
//       ),
//       body: categoriesAsync.when(
//         data: (categories) {
//           return Column(
//             children: [
//               const Padding(
//                 padding: EdgeInsets.all(16.0),
//                 child: Text(
//                   '대화할 주제의 카테고리를 선택하세요 💬',
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//               ),
//               Expanded(
//                 child: ListView.builder(
//                   itemCount: categories.length,
//                   itemBuilder: (context, index) {
//                     final category = categories[index];
//                     final isSelected = selectedCategory == category;
//
//                     return ListTile(
//                       title: Text(
//                         category.name,
//                         style: TextStyle(
//                           fontFamily: 'GowunBatang',
//                           fontSize: 16,
//                           color: isSelected ? Colors.pinkAccent : Colors.black87,
//                         ),
//                       ),
//                       trailing: isSelected
//                           ? const Icon(Icons.check_circle, color: Colors.pinkAccent)
//                           : const Icon(Icons.circle_outlined, color: Colors.grey),
//                       onTap: () {
//                         ref.read(selectedCategoryProvider.notifier).state = category;
//                       },
//                     );
//                   },
//                 ),
//               ),
//
//               // ✅ 하단 버튼
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
//                 child: ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.pinkAccent,
//                     minimumSize: const Size(double.infinity, 48),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   onPressed: selectedCategory == null
//                       ? null
//                       : () async {
//                     try {
//                       // 🔐 토큰 확인
//                       final token = await AuthService.getToken();
//                       if (token == null) {
//                         if (context.mounted) {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             const SnackBar(content: Text("로그인이 필요합니다.")),
//                           );
//                         }
//                         return;
//                       }
//
//                       final userId = ref.read(currentUserProvider);
//                       final chatRepo = ref.read(chatRepositoryProvider);
//
//                       // ✅ 채팅 세션 생성 (REST /api/chat/rooms)
//                       final ChatRoom room = await chatRepo.startSession();
//                       debugPrint("✅ 세션 생성 성공: ${room.chatSessionId}");
//
//                       // ✅ 메시지 구독
//                       chatRepo.subscribeMessages(room.chatSessionId).listen(
//                             (ChatMessage msg) {
//                           debugPrint("📩 메시지 수신: ${msg.content}");
//                         },
//                       );
//
//                       // ✅ 이벤트 구독
//                       if (chatRepo is ChatRepositoryImpl) {
//                         chatRepo
//                             .subscribeEvents(room.chatSessionId)
//                             .listen((ChatRoomEvent event) {
//                           debugPrint("📡 이벤트 수신: ${event.eventType}");
//
//                           // 🔹 대화 종료 이벤트
//                           if (event.eventType == "CONVERSATION_ENDED") {
//                             if (context.mounted) {
//                               Navigator.pushReplacementNamed(
//                                 context,
//                                 '/analysis',
//                                 arguments: {'sessionId': room.chatSessionId},
//                               );
//                             }
//                           }
//
//                           // 🔹 대화 시작 (주제 선택 완료)
//                           if (event.eventType == "CONVERSATION_STARTED") {
//                             final topic = event.payload?['topic'] ??
//                                 "주제가 선택되었습니다.";
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               SnackBar(content: Text('주제: $topic')),
//                             );
//                           }
//                         });
//                       }
//
//                       // ✅ 주제 선택 STOMP 전송
//                       chatRepo.sendCategorySelect(
//                         chatSessionId: room.chatSessionId,
//                         categoryId: selectedCategory.categoryId,
//                       );
//
//                       // ✅ 채팅방 화면으로 이동
//                       if (context.mounted) {
//                         Navigator.pushNamed(
//                           context,
//                           '/chat',
//                           arguments: {
//                             'room': room,
//                             'topic': selectedCategory.name,
//                             'currentUserId': userId ?? "unknown",
//                           },
//                         );
//                       }
//                     } catch (e) {
//                       debugPrint("❌ 세션 생성 실패: $e");
//                       if (context.mounted) {
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           SnackBar(content: Text('채팅방 생성 실패: $e')),
//                         );
//                       }
//                     }
//                   },
//                   child: const Text(
//                     '대화 시작',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontFamily: 'GowunBatang',
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           );
//         },
//         loading: () => const Center(child: CircularProgressIndicator()),
//         error: (e, _) => Center(
//           child: Text(
//             '카테고리 로드 실패: $e',
//             style: const TextStyle(fontFamily: 'GowunBatang'),
//           ),
//         ),
//       ),
//     );
//   }
// }
