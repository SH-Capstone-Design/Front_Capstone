import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:connectbeat/services/auth_service.dart';

class CoupleService {
  static final String _baseUrl = dotenv.env['BASE_URL'] ?? "";

  /// 🔹 커플 상태 조회 (내 커플 상태 + 파트너 정보 포함)
  static Future<Map<String, dynamic>?> fetchCoupleStatus() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse("$_baseUrl/couples/status"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json; charset=utf-8",
        },
      );

      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final data = json.decode(decoded);

        return {
          "status": data["status"],
          "coupleId": data["coupleId"],
          "partnerId": data["partnerId"],
          "partnerNickname": data["partnerNickname"],
          "partnerProfileImage": data["partnerProfileImage"],
          "anniversaryDate": data["anniversaryDate"],
          "linkedAt": data["linkedAt"],
        };
      } else {
        debugPrint(
            "❌ CoupleService fetchCoupleStatus failed: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("❌ CoupleService fetchCoupleStatus error: $e");
      return null;
    }
  }

  /// 🔹 커플 해제
  static Future<bool> unlinkCouple(String token) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/couples/unlink"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json; charset=utf-8",
        },
      );

      if (response.statusCode == 200) {
        debugPrint("✅ 커플 해제 성공");
        return true;
      } else {
        debugPrint("❌ 커플 해제 실패: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      debugPrint("❌ CoupleService unlinkCouple error: $e");
      return false;
    }
  }
}
