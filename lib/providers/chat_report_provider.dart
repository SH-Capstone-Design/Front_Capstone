import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/chat_report_service.dart';

/// 커플 ID 기준 리포트 목록
final chatReportListProvider = FutureProvider.family<List<Map<String, dynamic>>, int>((ref, coupleId) {
  return ChatReportService.fetchReportList(coupleId);
});

/// 리포트 ID 기준 상세
final chatReportDetailProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, reportId) {
  return ChatReportService.fetchReportDetail(reportId);
});
