import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart'; // JWT 헤더 가져오기

class CoinService {
  final String baseUrl;

  CoinService({required this.baseUrl});

  /// 🔹 커플 공용 코인 잔액 조회
  Future<int> fetchCoinBalance() async {
    final headers = await AuthService.buildAuthHeader();
    final url = Uri.parse('$baseUrl/coins/balance');
    print('📡 [GET] 코인 잔액 조회 요청: $url');
    print('📦 Headers: $headers');

    try {
      final response = await http.get(url, headers: headers);
      print('📩 [응답] ${response.statusCode}: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return int.tryParse(data['coinBalance'].toString()) ?? 0;
      } else if (response.statusCode == 401) {
        print('🚫 인증 실패 (401): 토큰이 없거나 만료됨');
        await AuthService.deleteToken();
        return 0;
      } else {
        throw Exception('코인 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 코인 조회 중 오류 발생: $e');
      return 0;
    }
  }

  /// 🔹 아이템 구매 (코인 차감)
  Future<Map<String, dynamic>> purchaseItem(int itemId) async {
    final headers = await AuthService.buildAuthHeader();
    final url = Uri.parse('$baseUrl/store/purchase');
    print('🛒 [POST] 아이템 구매 요청: $url, itemId=$itemId');

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode({'itemId': itemId}),
      );

      print('📩 [응답] ${response.statusCode}: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        throw Exception('인증 실패: 로그인 필요');
      } else {
        throw Exception('아이템 구매 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 아이템 구매 중 오류: $e');
      rethrow;
    }
  }

  /// 🔹 코인 직접 갱신 (서버 반영용, 선택사항)
  Future<bool> updateCoin(int newCoin) async {
    final headers = await AuthService.buildAuthHeader();
    final url = Uri.parse('$baseUrl/coins/update');
    print('💰 [POST] 코인 업데이트 요청: $url → $newCoin');

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode({'coin': newCoin}),
      );

      print('📩 [응답] ${response.statusCode}: ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ 코인 업데이트 오류: $e');
      return false;
    }
  }
}
