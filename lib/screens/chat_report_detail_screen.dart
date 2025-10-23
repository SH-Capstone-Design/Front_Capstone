import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_report_provider.dart';
import '../core/constants.dart';

class ChatReportDetailScreen extends ConsumerWidget {
  final String reportId;
  const ChatReportDetailScreen({super.key, required this.reportId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(chatReportDetailProvider(reportId));

    const titleFontSize = 22.0;
    const infoFontSize = 18.0;

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
            child: reportAsync.when(
              data: (report) {
                // report가 null인지 먼저 체크
                if (report == null) {
                  return const Center(
                    child: Text(
                      '리포트 데이터를 불러오지 못했습니다.',
                      style: TextStyle(
                        fontFamily: 'GowunBatang',
                        fontSize: infoFontSize,
                        color: Colors.black54,
                      ),
                    ),
                  );
                }

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
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => Center(
                child: Text(
                  '에러: $err',
                  style: const TextStyle(
                    fontFamily: 'GowunBatang',
                    fontSize: infoFontSize,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
