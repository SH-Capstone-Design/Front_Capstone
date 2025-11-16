import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class AttendanceService {
  final String baseUrl;

  AttendanceService({required this.baseUrl});

  /// 🔹 출석 체크
  Future<Map<String, dynamic>> checkIn() async {
    final headers = await AuthService.buildAuthHeader();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/attendance/check-in'),
        headers: headers,
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'alreadyChecked': false,
          'coinGained': data['coinGained'] ?? 0,
          'consecutiveDays': data['consecutiveDays'] ?? 0,
          'newTotalCoinBalance': data['newTotalCoinBalance'] ?? 0,
          'message': data['message'] ?? '출석 체크 완료',
        };
      }

      // 이미 출석한 경우
      if (response.statusCode == 409 && response.body.isNotEmpty) {
        final data = json.decode(response.body);
        return {
          'success': false,
          'alreadyChecked': true,
          'message': data['message'] ?? '오늘 이미 출석하셨습니다.',
        };
      }

      return {
        'success': false,
        'alreadyChecked': false,
        'message': '출석 체크 실패: 알 수 없는 오류',
      };
    } catch (e) {
      return {
        'success': false,
        'alreadyChecked': false,
        'message': '출석 체크 실패: ${e.toString()}',
      };
    }
  }

  /// 🔹 현재 출석 상태 조회
  Future<Map<String, dynamic>> getStatus() async {
    final headers = await AuthService.buildAuthHeader();

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/attendance/status'),
        headers: headers,
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = json.decode(response.body);

        return {
          'success': true,
          'todayChecked': data['todayChecked'] ?? false,
          'consecutiveDays': data['consecutiveDays'] ?? 0,
          'newTotalCoinBalance': data['newTotalCoinBalance'] ?? 0,
        };
      }

      return {
        'success': false,
        'todayChecked': false,
        'consecutiveDays': 0,
        'newTotalCoinBalance': 0,
      };
    } catch (e) {
      return {
        'success': false,
        'todayChecked': false,
        'consecutiveDays': 0,
        'newTotalCoinBalance': 0,
        'message': e.toString(),
      };
    }
  }
}
