import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ChatReportService {
  static final String baseUrl_1 = dotenv.env['BASE_URL_1'] ?? "";

  /// 커플 ID로 리포트 목록 조회
  static Future<List<Map<String, dynamic>>> fetchReportList(int coupleId) async {
    final response = await http.get(Uri.parse('$baseUrl_1/chat-report/list?coupleId=$coupleId'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => e as Map<String, dynamic>).toList();
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception('리포트 목록 조회 실패');
    }
  }

  /// 리포트 ID로 상세 조회
  static Future<Map<String, dynamic>> fetchReportDetail(String reportId) async {
    final response = await http.get(Uri.parse('$baseUrl_1/chat-report/$reportId'));
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('리포트 상세 조회 실패');
    }
  }
}
