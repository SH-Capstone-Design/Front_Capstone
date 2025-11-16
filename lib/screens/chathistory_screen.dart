import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:connectbeat/core/constants.dart';
import 'package:connectbeat/services/chat_report_service.dart';
import 'package:connectbeat/services/couple_service.dart';

class ChatHistoryScreen extends StatefulWidget {
  final String reportId;
  final int minute;

  const ChatHistoryScreen({
    super.key,
    required this.reportId,
    required this.minute,
  });

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  List<Map<String, dynamic>> filteredChats = [];
  bool isLoading = true;

  String currentUserId = "";
  String partnerId = "";
  String partnerNickname = "";
  String partnerProfile = "";

  @override
  void initState() {
    super.initState();
    _loadCoupleInfoAndChats();
  }

  Future<void> _loadCoupleInfoAndChats() async {
    try {
      final coupleData = await CoupleService.fetchCoupleStatus();
      if (coupleData != null) {
        setState(() {
          currentUserId = coupleData['myId'] ?? "";
          partnerId = coupleData['partnerId'] ?? "";
          partnerNickname = coupleData['partnerNickname'] ?? "상대방";
          partnerProfile = coupleData['partnerProfileImage'] ?? "";
        });
      }
      await _loadChatHistory();
    } catch (e) {
      debugPrint("❌ ChatHistoryScreen load error: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadChatHistory() async {
    final report = await ChatReportService.getReportById(widget.reportId);
    if (report == null || report['detailedEmotions'] == null) {
      setState(() => isLoading = false);
      return;
    }

    final List<dynamic> detailed = report['detailedEmotions'];
    if (detailed.isEmpty) {
      setState(() => isLoading = false);
      return;
    }

    final firstTime = DateTime.parse(detailed.first['sentAt']).toLocal();
    final start = firstTime.add(Duration(minutes: widget.minute - 1));
    final end = start.add(const Duration(minutes: 1));

    final chatsInMinute = detailed.where((msg) {
      final sentAt = DateTime.parse(msg['sentAt']).toLocal();
      return !sentAt.isBefore(start) && sentAt.isBefore(end);
    }).map((e) => Map<String, dynamic>.from(e as Map)).toList();

    setState(() {
      filteredChats = chatsInMinute;
      isLoading = false;
    });
  }

  String formatTime(String sentAt) {
    final date = DateTime.parse(sentAt).toLocal();
    return DateFormat('HH:mm').format(date);
  }

  Widget _buildMessageContent(String content) {
    final isImageUrl = content.startsWith('http') &&
        (content.endsWith('.png') ||
            content.endsWith('.jpg') ||
            content.endsWith('.jpeg') ||
            content.endsWith('.gif') ||
            content.contains('/emoji/'));

    if (isImageUrl) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          content,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
          const Icon(Icons.broken_image, size: 40, color: Colors.grey),
        ),
      );
    } else {
      return Text(
        content,
        style: const TextStyle(
          fontSize: 15,
          fontFamily: 'GowunBatang',
          color: Colors.black87,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // 배경 이미지가 앱바까지 올라가도록
      appBar: AppBar(
        backgroundColor: Colors.transparent, // 완전 투명
        elevation: 0,
        foregroundColor: Colors.black,
        centerTitle: true,
        title: Text(
          "${widget.minute}분대 대화기록",
          style: const TextStyle(
            fontFamily: 'GowunBatang',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppConstants.backgroundPath),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredChats.isEmpty
              ? const Center(
            child: Text(
              "해당 시간대의 대화가 없습니다.",
              style: TextStyle(
                fontFamily: 'GowunBatang',
                fontSize: 15,
                color: Colors.black54,
              ),
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            itemCount: filteredChats.length,
            itemBuilder: (context, index) {
              final msg = filteredChats[index];
              final isMine = msg['speaker'] != partnerId;
              final sentTime = formatTime(msg['sentAt']);
              final topEmotion = msg['topEmotion'] ?? '중립';
              final confidence =
              ((msg['confidence'] as num?) ?? 0 * 100)
                  .toStringAsFixed(0);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: isMine
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isMine)
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFFFFC1D9),
                        backgroundImage: partnerProfile.isNotEmpty
                            ? NetworkImage(partnerProfile)
                            : null,
                        child: partnerProfile.isEmpty
                            ? const Icon(Icons.person,
                            color: Colors.white)
                            : null,
                      ),
                    if (!isMine) const SizedBox(width: 8),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: isMine
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          if (!isMine)
                            Padding(
                              padding:
                              const EdgeInsets.only(bottom: 2),
                              child: Text(
                                partnerNickname,
                                style: const TextStyle(
                                  fontFamily: 'GowunBatang',
                                  fontSize: 13,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            constraints:
                            const BoxConstraints(maxWidth: 280),
                            decoration: BoxDecoration(
                              color: msg['sentence']
                                  .toString()
                                  .startsWith('http')
                                  ? Colors.transparent
                                  : (isMine
                                  ? const Color(0xFFFFC1D9)
                                  : Colors.white),
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(
                                    isMine ? 16 : 0),
                                bottomRight: Radius.circular(
                                    isMine ? 0 : 16),
                              ),
                              boxShadow: [
                                if (!msg['sentence']
                                    .toString()
                                    .startsWith('http'))
                                  BoxShadow(
                                    color: Colors.black
                                        .withOpacity(0.05),
                                    blurRadius: 4,
                                  ),
                              ],
                            ),
                            child: _buildMessageContent(
                                msg['sentence'] ?? ''),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                top: 3, right: 6, left: 6),
                            child: Text(
                              '$sentTime  $topEmotion $confidence%',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
