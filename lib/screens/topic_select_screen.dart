// // lib/screens/topic_select_screen.dart
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:connectbeat/providers/topic_provider.dart';
// import 'package:connectbeat/providers/current_user_provider.dart';
// import 'package:connectbeat/providers/chat_room_controller.dart';
// import 'package:connectbeat/providers/session_provider.dart';
// import 'package:connectbeat/services/auth_service.dart';
// import 'package:connectbeat/models/chat_room.dart';
//
// class TopicSelectScreen extends ConsumerWidget {
//   const TopicSelectScreen({super.key});
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final categoriesAsync = ref.watch(topicCategoriesProvider);
//     final selectedCategory = ref.watch(selectedCategoryProvider);
//     final userAsync = ref.watch(currentUserProvider); // ✅ 변경된 부분
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
//       body: userAsync.when(
//         data: (userData) {
//           if (userData == null) {
//             return const Center(child: Text("로그인이 필요합니다."));
//           }
//           final userId = userData['userId'].toString();
//
//           return categoriesAsync.when(
//             data: (categories) {
//               return Column(
//                 children: [
//                   const Padding(
//                     padding: EdgeInsets.all(16.0),
//                     child: Text(
//                       '대화할 주제의 카테고리를 선택하세요 💬',
//                       style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                     ),
//                   ),
//
//                   // ✅ 카테고리 리스트
//                   Expanded(
//                     child: ListView.builder(
//                       itemCount: categories.length,
//                       itemBuilder: (context, index) {
//                         final category = categories[index];
//                         final isSelected = selectedCategory == category;
//
//                         return ListTile(
//                           title: Text(
//                             category.name,
//                             style: TextStyle(
//                               fontFamily: 'GowunBatang',
//                               fontSize: 16,
//                               color: isSelected ? Colors.pinkAccent : Colors.black87,
//                             ),
//                           ),
//                           trailing: isSelected
//                               ? const Icon(Icons.check_circle, color: Color(0xFFFFEEFF))
//                               : const Icon(Icons.circle_outlined, color: Colors.grey),
//                           onTap: () {
//                             ref.read(selectedCategoryProvider.notifier).state = category;
//                           },
//                         );
//                       },
//                     ),
//                   ),
//
//                   // ✅ "대화 시작" 버튼
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
//                     child: ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.pinkAccent,
//                         minimumSize: const Size(double.infinity, 48),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                       onPressed: () async {
//                         try {
//                           final token = await AuthService.getToken();
//                           if (token == null) {
//                             if (context.mounted) {
//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 const SnackBar(content: Text("로그인이 필요합니다.")),
//                               );
//                             }
//                             return;
//                           }
//
//                           final partnerId = ref.read(sessionControllerProvider.notifier).partnerId ?? "unknown";
//                           final chatCtrl = ref.read(chatRoomControllerProvider.notifier);
//
//                           await chatCtrl.startSession(
//                             userId: userId,
//                             partnerId: partnerId,
//                           );
//
//                           final room = ref.read(chatRoomControllerProvider).room;
//                           if (room == null) {
//                             throw Exception("세션 생성 실패");
//                           }
//
//                           debugPrint("✅ 세션 생성 완료: ${room.chatSessionId}");
//
//                           final categoryId = selectedCategory?.categoryId ?? 1;
//                           final topicName = selectedCategory?.name ?? "테스트 주제";
//
//                           await chatCtrl.sendCategorySelect(
//                             chatSessionId: room.chatSessionId,
//                             categoryId: categoryId,
//                           );
//
//                           if (context.mounted) {
//                             Navigator.pushNamed(
//                               context,
//                               '/chat',
//                               arguments: {
//                                 'room': room,
//                                 'topic': topicName,
//                                 'currentUserId': userId,
//                               },
//                             );
//                           }
//                         } catch (e) {
//                           debugPrint("❌ 대화 시작 실패: $e");
//                           if (context.mounted) {
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               SnackBar(content: Text('대화 시작 실패: $e')),
//                             );
//                           }
//                         }
//                       },
//                       child: const Text(
//                         '대화 시작',
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontFamily: 'GowunBatang',
//                           color: Colors.white,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               );
//             },
//             loading: () => const Center(child: CircularProgressIndicator()),
//             error: (e, _) => Center(child: Text('카테고리 로드 실패: $e')),
//           );
//         },
//         loading: () => const Center(child: CircularProgressIndicator()),
//         error: (e, _) => Center(child: Text('유저 정보 로드 실패: $e')),
//       ),
//     );
//   }
// }
