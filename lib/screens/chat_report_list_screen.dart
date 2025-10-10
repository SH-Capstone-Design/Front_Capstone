import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_report_provider.dart';
import 'chat_report_detail_screen.dart';
import '../core/constants.dart';

class ChatReportListScreen extends ConsumerWidget {
  final int coupleId;
  const ChatReportListScreen({super.key, required this.coupleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportListAsync = ref.watch(chatReportListProvider(coupleId));

    const titleFontSize = 22.0;
    const infoFontSize = 18.0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          '대화 리포트 목록',
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
            child: reportListAsync.when(
              data: (reports) {
                if (reports.isEmpty) {
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
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    final reportId = report['reportId'] ?? 'N/A';
                    final summary = report['shortFeedbackSummary'] ?? '';
                    final createdAt = report['createdAt']?.substring(0, 10) ?? '';

                    return Card(
                      color: Colors.white70,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Text(
                          '리포트 $reportId',
                          style: const TextStyle(
                            fontFamily: 'GowunBatang',
                            fontSize: infoFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          summary,
                          style: const TextStyle(
                            fontFamily: 'GowunBatang',
                            fontSize: infoFontSize - 2,
                            color: Colors.black87,
                          ),
                        ),
                        trailing: Text(
                          createdAt,
                          style: const TextStyle(
                            fontFamily: 'GowunBatang',
                            fontSize: infoFontSize - 4,
                            color: Colors.black54,
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatReportDetailScreen(reportId: reportId),
                            ),
                          );
                        },
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
