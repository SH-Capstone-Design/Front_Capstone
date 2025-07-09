import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

import 'auth_service.dart';

class ApiService {
  static Future<http.Response> postWithAuth(String endpoint, {Map<String, dynamic>? body}) async {
    final token = await AuthService.getToken();

    return await http.post(
      Uri.parse('${dotenv.env['BASE_URL']}$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: body != null ? jsonEncode(body) : null,
    );
  }

  static Future<http.Response> getWithAuth(String endpoint) async {
    final token = await AuthService.getToken();

    return await http.get(
      Uri.parse('${dotenv.env['BASE_URL']}$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
  }
}
