import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_report_provider.dart';
import 'chat_report_detail_screen.dart';
import '../core/constants.dart';

class ChatReportListScreen extends ConsumerWidget {
  final int? coupleId;

  const ChatReportListScreen({super.key, required this.coupleId});

  String formatReportTitle(String? createdAt) {
    if (createdAt == null || createdAt.isEmpty) return "감정 리포트";
    final dt = DateTime.tryParse(createdAt);
    if (dt == null) return "감정 리포트";
    return "${dt.year}년 ${dt.month}월 ${dt.day}일의 감정 리포트";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const infoFontSize = 18.0;

    if (coupleId == null) {
      return const Center(
        child: Text(
          '커플 정보가 없습니다.',
          style: TextStyle(
            fontFamily: 'GowunBatang',
            fontSize: infoFontSize,
            color: Colors.black54,
          ),
        ),
      );
    }

    final reportListAsync = ref.watch(chatReportListProvider(coupleId!));

    return Scaffold(
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
            child: reportListAsync.when(
              data: (reports) {
                if (reports.isEmpty) {
                  return const Center(
                    child: Text(
                      '리포트가 없습니다.',
                      style: TextStyle(
                        fontFamily: 'GowunBatang',
                        fontSize: 18,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      '대화 리포트 목록',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'GowunBatang',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: reports.length,
                        itemBuilder: (context, index) {
                          final report = reports[index];
                          final reportId = report['reportId'] ?? '';
                          final summary = report['shortFeedbackSummary'] ?? '';
                          final createdAt = report['createdAt'] ?? '';

                          return Card(
                            color: Colors.white,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              title: Text(
                                formatReportTitle(createdAt),
                                style: const TextStyle(
                                  fontFamily: 'GowunBatang',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: summary.isNotEmpty
                                  ? Text(
                                summary,
                                style: const TextStyle(
                                  fontFamily: 'GowunBatang',
                                ),
                              )
                                  : null,
                              onTap: () {
                                if (reportId.isNotEmpty) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ChatReportDetailScreen(reportId: reportId),
                                    ),
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
              loading: () =>
              const Center(child: CircularProgressIndicator(color: Colors.black)),
              error: (err, _) => Center(
                child: Text(
                  '에러: $err',
                  style: const TextStyle(
                      fontFamily: 'GowunBatang', color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
