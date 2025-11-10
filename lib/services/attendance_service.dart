import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class AttendanceService {
  final String baseUrl;

  AttendanceService({required this.baseUrl});

  Future<Map<String, dynamic>> checkIn() async {
    final headers = await AuthService.buildAuthHeader();
    print('Headers: $headers');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/attendance/check-in'),
        headers: headers,
      );

      print('AttendanceService statusCode: ${response.statusCode}');
      print('AttendanceService response.body: ${response.body}');

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? '출석 완료',
          'coinGained': data['coinGained'] ?? 0,
          'consecutiveDays': data['consecutiveDays'] ?? 0,
          'newTotalCoinBalance': data['newTotalCoinBalance'] ?? 0,
        };
      } else if (response.statusCode == 400 || response.statusCode == 403) {
        // 이미 출석했거나 토큰 문제
        final data = response.body.isNotEmpty ? json.decode(response.body) : {};
        return {
          'success': false,
          'alreadyCheckedIn': true,
          'message': data['message'] ?? '오늘 이미 출석 완료',
          'coinGained': 0,
          'consecutiveDays': 0,
          'newTotalCoinBalance': 0,
        };
      } else {
        return {
          'success': false,
          'message': '출석 체크 실패: ${response.statusCode}',
          'coinGained': 0,
          'consecutiveDays': 0,
          'newTotalCoinBalance': 0,
        };
      }
    } catch (e) {
      print('AttendanceService Exception: $e');
      return {
        'success': false,
        'message': '출석 체크 중 오류 발생',
        'coinGained': 0,
        'consecutiveDays': 0,
        'newTotalCoinBalance': 0,
      };
    }
  }
}
