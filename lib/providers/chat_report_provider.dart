import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/chat_report_service.dart';

/// 🔹 커플 ID 기준 리포트 목록 조회 Provider
final chatReportListProvider =
FutureProvider.family<List<Map<String, dynamic>>, int>((ref, coupleId) async {
  return await ChatReportService.getReportListByCouple(coupleId);
});

/// 🔹 세션 ID 기준 리포트 조회 Provider
final chatReportBySessionProvider =
FutureProvider.family<Map<String, dynamic>?, String>((ref, chatSessionId) async {
  return await ChatReportService.getReportBySession(chatSessionId);
});

/// 🔹 reportId 기준 리포트 조회 Provider
final chatReportByIdProvider =
FutureProvider.family<Map<String, dynamic>?, String>((ref, reportId) async {
  return await ChatReportService.getReportById(reportId);
});
