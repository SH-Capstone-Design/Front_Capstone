import 'dart:convert';
import 'package:connectbeat/services/auth_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatReportService {
  static final String baseUrl_1 = dotenv.env['BASE_URL'] ?? "";

  /// 🔹 리포트 생성
  static Future<Map<String, dynamic>?> generateReport({
    required String chatSessionId,
    required String feedback,
  }) async {
    final token = await AuthService.getToken();

    if (token == null) {
      throw Exception("🚫 로그인 토큰이 없습니다. 인증 실패");
    }

    final url = Uri.parse('$baseUrl_1/chat-report/generate');
    debugPrint("📤 [POST] $url");

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'chatSessionId': chatSessionId,
        'feedback': feedback,
      }),
    );

    debugPrint("🧩 리포트 생성 응답 코드: ${response.statusCode}");
    debugPrint("🧩 응답 본문: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      debugPrint("⚠️ 리포트 생성 실패 (status: ${response.statusCode})");
      return null;
    }
  }

  /// 🔹 2. 커플 ID로 리포트 목록 조회 (GET /chat-report/list)
  static Future<List<Map<String, dynamic>>> fetchReportList(int coupleId) async {
    try {
      final url = Uri.parse('$baseUrl_1/chat-report/list?coupleId=$coupleId');
      debugPrint("📥 [GET] $url");

      final response = await http.get(url);
      debugPrint("🧩 목록 응답 코드: ${response.statusCode}");

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => e as Map<String, dynamic>).toList();
      } else if (response.statusCode == 404) {
        debugPrint("⚠️ 리포트 없음 (404)");
        return [];
      } else {
        throw Exception('리포트 목록 조회 실패 (${response.statusCode})');
      }
    } catch (e, st) {
      debugPrint("🚨 fetchReportList() 오류: $e\n$st");
      return [];
    }
  }

  /// 🔹 3. 리포트 ID로 상세 조회 (GET /chat-report/{reportId})
  static Future<Map<String, dynamic>?> fetchReportDetail(String reportId) async {
    try {
      final url = Uri.parse('$baseUrl_1/chat-report/$reportId');
      debugPrint("📥 [GET] $url");

      final response = await http.get(url);
      debugPrint("🧩 상세 조회 응답 코드: ${response.statusCode}");

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        debugPrint("⚠️ 리포트 상세 조회 실패 (${response.statusCode})");
        return null;
      }
    } catch (e, st) {
      debugPrint("🚨 fetchReportDetail() 오류: $e\n$st");
      return null;
    }
  }

  /// 🔹 4. 세션 ID로 리포트 상세 조회 (GET /chat-report/by-session/{sessionId})
  static Future<Map<String, dynamic>?> fetchReportBySession(String sessionId) async {
    try {
      // ✅ 로그인 토큰 가져오기
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception("🚫 로그인 토큰이 없습니다. 인증 실패");
      }

      final url = Uri.parse('$baseUrl_1/chat-report/by-session/$sessionId');
      debugPrint("📥 [GET] $url");

      // ✅ JWT 헤더 추가
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint("🧩 세션 기반 조회 코드: ${response.statusCode}");
      debugPrint("🧩 응답 본문: ${response.body}");

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 404) {
        debugPrint("⚠️ 해당 세션 리포트 없음 (404)");
        return null;
      } else {
        debugPrint("⚠️ 조회 실패: ${response.statusCode}");
        return null;
      }
    } catch (e, st) {
      debugPrint("🚨 fetchReportBySession() 오류: $e\n$st");
      return null;
    }
  }
}
