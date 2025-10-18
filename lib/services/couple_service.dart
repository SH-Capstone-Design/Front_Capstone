// lib/services/couple_service.dart
import 'dart:convert';
import 'package:connectbeat/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CoupleService {
  static final String _baseUrl = dotenv.env['BASE_URL'] ?? "";

  /// 커플 상태 조회
  static Future<Map<String, dynamic>?> fetchCoupleStatus() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse("$_baseUrl/couples/status"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        // ✅ utf8.decode로 한글 깨짐 방지
        final decoded = utf8.decode(response.bodyBytes);
        final data = json.decode(decoded);
        return data;
      } else {
        debugPrint("CoupleService: 상태 조회 실패 ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("CoupleService: 상태 조회 에러 $e");
      return null;
    }
  }
}
