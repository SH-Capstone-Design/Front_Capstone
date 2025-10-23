import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/chat_report_service.dart';

/// 🔹 커플 ID 기준 리포트 목록 조회 Provider
final chatReportListProvider = FutureProvider.family<List<Map<String, dynamic>>, int>((ref, coupleId) async {
  return await ChatReportService.fetchReportList(coupleId);
});

/// 🔹 리포트 ID 기준 상세 조회 Provider
final chatReportDetailProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, reportId) async {
  return await ChatReportService.fetchReportDetail(reportId);
});
