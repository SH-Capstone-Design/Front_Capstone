import 'dart:convert';
import 'package:connectbeat/services/auth_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatReportService {
  static final String baseUrl = dotenv.env['BASE_URL'] ?? "";

  /// 🔹 1. 세션 ID 기준 리포트 조회 (GET)
  static Future<Map<String, dynamic>?> generateReport(String chatSessionId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception("🚫 로그인 토큰이 없습니다. 인증 실패");
      }

      final url = Uri.parse('$baseUrl/chat-report/by-session/$chatSessionId');
      debugPrint("📥 [GET] $url");

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint("🧩 응답 코드: ${response.statusCode}");
      debugPrint("🧩 응답 본문: ${response.body}");

      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        return jsonDecode(body) as Map<String, dynamic>;
      } else if (response.statusCode == 404) {
        debugPrint("⚠️ 리포트 없음 (404)");
        return null;
      } else {
        throw Exception('리포트 조회 실패 (${response.statusCode})');
      }
    } catch (e, st) {
      debugPrint("🚨 fetchReportBySession() 오류: $e\n$st");
      return null;
    }
  }



  /// 🔹 2. 커플 ID로 리포트 목록 조회
  /// 리포트 목록 화면에서 커플의 전체 리포트를 불러올 때 사용.
  static Future<List<Map<String, dynamic>>> fetchReportList(int coupleId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception("🚫 로그인 토큰이 없습니다. 인증 실패");
      }

      final url = Uri.parse('$baseUrl/chat-report/list?coupleId=$coupleId');
      debugPrint("📥 [GET] $url");

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint("🧩 목록 응답 코드: ${response.statusCode}");

      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        final List<dynamic> data = json.decode(body);
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

  /// 🔹 3. reportId 기준 리포트 조회 (GET)
  static Future<Map<String, dynamic>?> generateReportById(String reportId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception("🚫 로그인 토큰이 없습니다. 인증 실패");
      }

      final url = Uri.parse('$baseUrl/chat-report/$reportId'); // 🔹 reportId 기준
      debugPrint("📥 [GET] $url");

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint("🧩 응답 코드: ${response.statusCode}");
      debugPrint("🧩 응답 본문: ${response.body}");

      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        return jsonDecode(body) as Map<String, dynamic>;
      } else if (response.statusCode == 404) {
        debugPrint("⚠️ 리포트 없음 (404)");
        return null;
      } else {
        throw Exception('리포트 조회 실패 (${response.statusCode})');
      }
    } catch (e, st) {
      debugPrint("🚨 fetchReportById() 오류: $e\n$st");
      return null;
    }
  }
}
