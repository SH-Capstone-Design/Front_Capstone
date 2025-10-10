// lib/services/topic_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:connectbeat/models/topic.dart';

/// 🧩 주제 관련 API 서비스
/// - 카테고리 목록 조회
/// - 랜덤 주제 선택
class TopicService {
  final String _baseUrl = dotenv.env['BASE_URL'] ?? '';

  /// 전체 카테고리 목록 조회
  Future<List<TopicCategory>> fetchCategories(String token) async {
    final url = Uri.parse('$_baseUrl/topics/categories');
    final res = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data.map((e) => TopicCategory.fromJson(e)).toList();
    } else {
      throw Exception('카테고리 목록 조회 실패 (${res.statusCode})');
    }
  }

  /// 선택된 카테고리 기반 랜덤 주제 가져오기
  Future<Topic> fetchRandomTopic({
    required String token,
    required int categoryId,
  }) async {
    final url = Uri.parse('$_baseUrl/topics/random?categoryId=$categoryId');
    final res = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (res.statusCode == 200) {
      return Topic.fromJson(jsonDecode(res.body));
    } else {
      throw Exception('랜덤 주제 조회 실패 (${res.statusCode})');
    }
  }
}
