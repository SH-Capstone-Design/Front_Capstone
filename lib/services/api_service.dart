import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  final String baseUrl;
  ApiService({required this.baseUrl});

  Future<String> generateCoupleCode({required String jwtToken}) async {
    final url = Uri.parse('$baseUrl/api/couples/code');
    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $jwtToken",
        "Content-Type": "application/json",
      },
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['code'] ?? '';
    } else {
      throw Exception('커플 코드 생성 실패: ${response.body}');
    }
  }
}
