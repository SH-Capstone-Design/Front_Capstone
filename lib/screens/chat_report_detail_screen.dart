import 'package:flutter/material.dart';
import 'package:connectbeat/services/chat_report_service.dart';
import 'package:connectbeat/core/constants.dart';

class ChatReportDetailScreen extends StatelessWidget {
  final String chatSessionId;
  const ChatReportDetailScreen({super.key, required this.chatSessionId});

  @override
  Widget build(BuildContext context) {
    const titleFontSize = 22.0;
    const infoFontSize = 18.0;
    const feedback = "이번 대화의 감정 분석 결과입니다.";

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          '리포트 상세',
          style: TextStyle(
            fontFamily: 'GowunBatang',
            fontSize: titleFontSize,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppConstants.backgroundPath),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: FutureBuilder<Map<String, dynamic>?>(
              future: ChatReportService.generateReport(
                chatSessionId, // GET용으로 chatSessionId만 전달
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      '에러: ${snapshot.error}',
                      style: const TextStyle(
                        fontFamily: 'GowunBatang',
                        fontSize: infoFontSize,
                        color: Colors.black,
                      ),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(
                    child: Text(
                      '리포트를 불러오지 못했습니다.',
                      style: TextStyle(
                        fontFamily: 'GowunBatang',
                        fontSize: infoFontSize,
                        color: Colors.black54,
                      ),
                    ),
                  );
                }

                final report = snapshot.data!;
                final detailedEmotions = report['detailedEmotions'] as List<dynamic>? ?? [];

                if (detailedEmotions.isEmpty) {
                  return const Center(
                    child: Text(
                      '리포트가 없습니다.',
                      style: TextStyle(
                        fontFamily: 'GowunBatang',
                        fontSize: infoFontSize,
                        color: Colors.black54,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: detailedEmotions.length,
                  itemBuilder: (context, index) {
                    final item = detailedEmotions[index];
                    final speaker = item['speaker'] ?? '알 수 없음';
                    final sentence = item['sentence'] ?? '';
                    final topEmotion = item['topEmotion'] ?? '-';
                    final confidence = item['confidence'] ?? 0;

                    return Card(
                      color: Colors.white70,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$speaker',
                              style: const TextStyle(
                                fontFamily: 'GowunBatang',
                                fontSize: infoFontSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              sentence,
                              style: const TextStyle(
                                fontFamily: 'GowunBatang',
                                fontSize: infoFontSize - 2,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '감정: $topEmotion (신뢰도: $confidence)',
                              style: const TextStyle(
                                fontFamily: 'GowunBatang',
                                fontSize: infoFontSize - 4,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
