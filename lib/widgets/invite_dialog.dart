// 상대방 폰 팝업 : 수락, 거절 버튼
import 'package:flutter/material.dart';

class InviteDialog extends StatelessWidget {
  final String inviterName; // 초대한 사람 이름(닉네임)
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const InviteDialog({
    super.key,
    required this.inviterName,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('$inviterName 님의 초대', style: const TextStyle(fontWeight: FontWeight.bold)),
      content: const Text('채팅방에 참여하시겠습니까?'),
      actions: [
        TextButton(
          onPressed: onAccept,
          child: const Text('수락'),
        ),
        TextButton(
          onPressed: onReject,
          child: const Text('거절'),
        ),
      ],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
