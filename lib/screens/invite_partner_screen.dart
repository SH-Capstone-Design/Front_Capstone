// // lib/screens/invite_partner_screen.dart
// import 'package:connectbeat/services/auth_service.dart';
// import 'package:connectbeat/services/chat_repository_impl.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:connectbeat/core/constants.dart';
// import 'package:connectbeat/widgets/rounded_button.dart';
// import 'package:connectbeat/providers/chat_repository_provider.dart';
// import 'package:connectbeat/providers/current_user_provider.dart';
// import 'package:connectbeat/models/chat_room_event.dart';
//
// class InvitePartnerScreen extends ConsumerWidget {
//   final String chatSessionId; // 이미 생성된 방 ID
//   final String inviteeId;     // 초대할 상대방 ID (커플 ID 기반으로 결정)
//
//   const InvitePartnerScreen({
//     super.key,
//     required this.chatSessionId,
//     required this.inviteeId,
//   });
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final size = MediaQuery.of(context).size;
//
//     return Scaffold(
//       backgroundColor: const Color(0xFFFFF8FC),
//       body: SafeArea(
//         child: Column(
//           children: [
//             SizedBox(height: size.height * 0.06),
//             Center(
//               child: Image.asset(
//                 AppConstants.logoPath,
//                 height: 50,
//                 fit: BoxFit.contain,
//               ),
//             ),
//             const Spacer(flex: 2),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 30),
//               child: RoundedButton(
//                 text: "상대방 초대",
//                 onPressed: () async {
//                   try {
//                     final token = await AuthService.getToken();
//                     if (token == null) {
//                       if (context.mounted) {
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           const SnackBar(content: Text("로그인이 필요합니다.")),
//                         );
//                       }
//                       return;
//                     }
//
//                     final chatRepo = ref.read(chatRepositoryProvider);
//                     final userId = ref.read(currentUserProvider) ?? "unknown";
//
//                     // ✅ 초대 전송 (전용 메서드 사용)
//                     if (chatRepo is ChatRepositoryImpl) {
//                       await chatRepo.sendInvite(
//                         chatSessionId: chatSessionId,
//                         inviteeId: inviteeId,
//                       );
//                     }
//
//                     // ✅ 이벤트 구독: 상대방이 수락하면 USER_JOINED 이벤트 발생
//                     if (chatRepo is ChatRepositoryImpl) {
//                       chatRepo.subscribeEvents(chatSessionId).listen(
//                             (ChatRoomEvent event) {
//                           if (event.eventType == "USER_JOINED") {
//                             debugPrint("👫 상대방 입장 확인!");
//                             if (context.mounted) {
//                               Navigator.pushReplacementNamed(
//                                 context,
//                                 '/topic-select',
//                                 arguments: {
//                                   'chatSessionId': chatSessionId,
//                                   'currentUserId': userId,
//                                 },
//                               );
//                             }
//                           }
//                         },
//                       );
//                     }
//
//                     if (context.mounted) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(content: Text("상대방 초대를 전송했습니다.")),
//                       );
//                     }
//                   } catch (e) {
//                     debugPrint("❌ 초대 실패: $e");
//                     if (context.mounted) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(content: Text('초대 실패: $e')),
//                       );
//                     }
//                   }
//                 },
//               ),
//             ),
//             const Spacer(flex: 3),
//           ],
//         ),
//       ),
//     );
//   }
// }
