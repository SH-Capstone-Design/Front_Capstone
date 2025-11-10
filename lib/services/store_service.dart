import 'dart:convert';
import 'package:connectbeat/models/store_models.dart';
import 'package:connectbeat/services/auth_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class StoreService {
  final String baseUrl = dotenv.env['BASE_URL'] ?? '';

  Future<List<StoreItemDTO>> fetchStoreItems() async {
    final headers = await AuthService.buildAuthHeader();
    final resp = await http.get(Uri.parse('$baseUrl/store/items'), headers: headers);
    if (resp.statusCode == 200) {
      final List data = json.decode(resp.body);
      return data.map((e) => StoreItemDTO.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('상점 아이템 조회 실패: ${resp.statusCode}');
  }

  Future<void> purchaseItem(int itemId) async {
    final headers = await AuthService.buildAuthHeader();
    headers['Content-Type'] = 'application/json';
    final resp = await http.post(
      Uri.parse('$baseUrl/store/purchase'),
      headers: headers,
      body: json.encode({'itemId': itemId}),
    );
    if (resp.statusCode != 200) throw Exception('아이템 구매 실패: ${resp.statusCode}');
  }
}
