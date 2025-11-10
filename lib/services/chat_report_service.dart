import 'dart:convert';
import 'package:connectbeat/services/auth_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatReportService {
  static final String baseUrl = dotenv.env['BASE_URL'] ?? "";

  /// ------------------------------
  /// 1️⃣ 공통 GET 요청 함수
  /// ------------------------------
  static Future<Map<String, dynamic>?> _get(String endpoint) async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) throw Exception("🚫 로그인 토큰이 없습니다.");

      final url = Uri.parse('$baseUrl/$endpoint');
      debugPrint("📥 [GET] $endpoint → $url");

      final response = await http
          .get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      )
          .timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception("⏱️ 서버 응답 지연 (5초 초과)"),
      );

      debugPrint("🧩 응답 코드: ${response.statusCode}");

      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        final data = jsonDecode(body) as Map<String, dynamic>?;
        return data;
      } else if (response.statusCode == 404) {
        debugPrint("⚠️ 리포트 없음 (404)");
        return null;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('❌ 인증 실패 (${response.statusCode})');
      } else {
        throw Exception('리포트 조회 실패 (${response.statusCode})');
      }
    } catch (e, st) {
      debugPrint("🚨 _get() 오류: $e\n$st");
      return null;
    }
  }

  /// ------------------------------
  /// 2️⃣ 세션 ID 기준 리포트 조회
  /// ------------------------------
  static Future<Map<String, dynamic>?> getReportBySession(String chatSessionId) async {
    return _get('chat-report/by-session/$chatSessionId');
  }

  /// ------------------------------
  /// 3️⃣ reportId 기준 리포트 조회
  /// ------------------------------
  static Future<Map<String, dynamic>?> getReportById(String reportId) async {
    return _get('chat-report/$reportId');
  }

  /// ------------------------------
  /// 4️⃣ GPT 피드백 포함 리포트까지 대기
  /// ------------------------------
  static Future<Map<String, dynamic>?> waitForReportWithFeedback(String chatSessionId,
      {int maxRetries = 20, Duration delay = const Duration(seconds: 2)}) async {
    Map<String, dynamic>? report;

    for (int i = 0; i < maxRetries; i++) {
      debugPrint("⏳ 리포트 생성 확인 중... (${i + 1}/$maxRetries)");
      report = await getReportBySession(chatSessionId);

      if (report != null) {
        final feedback = report['gptFeedback'];
        if (feedback != null && feedback.toString().isNotEmpty) {
          debugPrint("✅ GPT 피드백 포함 리포트 생성 완료!");
          return report;
        } else {
          debugPrint("⚠️ GPT 피드백 아직 생성 중...");
        }
      }

      await Future.delayed(delay);
    }

    debugPrint("❌ 제한 시간 내 리포트 생성 실패 ($maxRetries 회 시도)");
    return report;
  }

  /// ------------------------------
  /// 5️⃣ 커플 ID 기준 리포트 목록 조회
  /// ------------------------------
  static Future<List<Map<String, dynamic>>> getReportListByCouple(int coupleId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) throw Exception("🚫 로그인 토큰이 없습니다.");

      final url = Uri.parse('$baseUrl/chat-report/list?coupleId=$coupleId');
      debugPrint("📥 [GET] Chat Report List → $url");

      final response = await http
          .get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      )
          .timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception("⏱️ 서버 응답 지연 (5초 초과)"),
      );

      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        final List<dynamic> data = jsonDecode(body) as List<dynamic>? ?? [];
        return data.map((e) => e as Map<String, dynamic>).toList();
      } else if (response.statusCode == 404) {
        debugPrint("⚠️ 리포트 목록 없음 (404)");
        return [];
      } else {
        throw Exception('리포트 목록 조회 실패 (${response.statusCode})');
      }
    } catch (e, st) {
      debugPrint("🚨 getReportListByCouple() 오류: $e\n$st");
      return [];
    }
  }
}
