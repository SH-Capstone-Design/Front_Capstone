import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:connectbeat/services/date_websocket_service.dart';
import 'package:connectbeat/services/auth_service.dart';

final coupleDateProvider = StateNotifierProvider<CoupleDateNotifier, DateTime?>(
      (ref) => CoupleDateNotifier(),
);

class CoupleDateNotifier extends StateNotifier<DateTime?> {
  CoupleDateNotifier() : super(null) {
    // 💌 웹소켓 이벤트 수신 시 D-Day 갱신
    DateWebsocketService.setOnCoupleDDayUpdated((event) {
      final dateStr = event['payload']?['anniversaryDate'];
      if (dateStr != null) {
        final parsedDate = DateTime.tryParse(dateStr);
        if (parsedDate != null) {
          state = parsedDate;
          print("💖 실시간 D-Day 업데이트: $dateStr");
        }
      }
    });
  }

  /// 🗓 서버에서 받은 D-Day 초기화
  void setDate(DateTime date) {
    state = date;
    print("💌 D-Day 초기화: ${date.toIso8601String()}");
  }

  /// 🌐 D-Day 서버에 저장
  Future<void> saveToServer(DateTime date) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('JWT 토큰이 없습니다.');

    final url = Uri.parse('${dotenv.env['BASE_URL']}/couples/dday');
    final body = jsonEncode({
      'anniversaryDate': date.toIso8601String().split('T')[0], // YYYY-MM-DD
    });

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        state = date;
        print("✅ D-Day 서버 저장 성공: ${date.toIso8601String()}");
      } else {
        print("❌ D-Day 저장 실패: ${response.body}");
        throw Exception('D-Day 저장 실패: ${response.body}');
      }
    } catch (e) {
      print("❌ D-Day 서버 요청 실패: $e");
      throw Exception('D-Day 서버 요청 실패: $e');
    }
  }

  /// 💕 D-Day 텍스트 계산
  String getDDayText() {
    if (state == null) return '사귄 날짜를 설정해주세요';
    final now = DateTime.now();
    final diffDays = now.difference(state!).inDays + 1;
    if (diffDays <= 0) return '사귄 날짜를 올바르게 설정해주세요';
    return '우리가 만난지 $diffDays일 🩷';
  }
}
