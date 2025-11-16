import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/chat_report_provider.dart';
import '../core/constants.dart';
import 'chat_report_detail_screen.dart';

class ChatReportListScreen extends ConsumerWidget {
  final int? coupleId;

  const ChatReportListScreen({super.key, required this.coupleId});

  String formatReportTitle(String? createdAt) {
    if (createdAt == null || createdAt.isEmpty) return "감정 리포트";
    final dt = DateTime.tryParse(createdAt);
    if (dt == null) return "감정 리포트";
    return "${DateFormat('M월 d일').format(dt)}의 대화 기록";
  }

  Color getEmotionColor(String? emotion) {
    return const Color(0xFFFDDBFF);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportListAsync = ref.watch(chatReportListProvider(coupleId ?? -1));

    return Scaffold(
      extendBodyBehindAppBar: true,

      // 🔥 뒤로가기 완전 제거한 AppBar (제목만 중앙)
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // ← 뒤로가기 아이콘 제거
        centerTitle: true,
        title: const Text(
          "우리의 기록",
          style: TextStyle(
            fontFamily: 'GowunBatang',
            fontSize: 24,
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
          top: true,
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: reportListAsync.when(
              data: (reports) {
                if (reports.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('assets/images/empty_report.png', width: 180),
                        const SizedBox(height: 20),
                        const Text(
                          '아직 대화 리포트가 없어요 🕊️\n오늘은 어떤 감정이 오갔을까요?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'GowunBatang',
                            fontSize: 17,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final report = reports[index];

                    final reportId = report['reportId'].toString();
                    final summary = report['shortFeedbackSummary'] ?? '감정 요약이 없습니다.';
                    final createdAt = report['createdAt'] ?? '';
                    final mainEmotion = report['mainEmotion'] ?? '중립';
                    final color = getEmotionColor(mainEmotion);

                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Duration(milliseconds: 450 + index * 120),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 25 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatReportDetailScreen(reportId: reportId),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 18),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                color.withOpacity(0.35),
                                Colors.white.withOpacity(0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        formatReportTitle(createdAt),
                                        style: const TextStyle(
                                          fontFamily: 'GowunBatang',
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        summary,
                                        style: const TextStyle(
                                          fontFamily: 'GowunBatang',
                                          fontSize: 15,
                                          color: Colors.black54,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  color: Colors.black45,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: Colors.pinkAccent),
              ),
              error: (err, _) => Center(
                child: Text(
                  '에러 발생: $err',
                  style: const TextStyle(
                    fontFamily: 'GowunBatang',
                    color: Colors.redAccent,
                    fontSize: 16,
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
