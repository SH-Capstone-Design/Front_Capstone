import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_service.dart'; // JWT 토큰 가져오는 서비스

/// 서버에 이미지 업로드하고, 반환된 S3 URL을 받아오기
Future<String> uploadProfileImageToServer(File imageFile) async {
  final token = await AuthService.getToken();
  print("JWT 토큰: $token");
  if (token == null) {
    throw Exception('로그인 상태가 아닙니다.');
  }

  final uri = Uri.parse('${dotenv.env['BASE_URL']}/users/me/profile-image');

  final request = http.MultipartRequest('POST', uri)
    ..headers['Authorization'] = 'Bearer $token'
    ..files.add(await http.MultipartFile.fromPath('image', imageFile.path));

  final streamedResponse = await request.send();
  final response = await http.Response.fromStream(streamedResponse);

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data['profileImageUrl'] as String;
  } else if (response.statusCode == 401) {
    throw Exception('인증 실패: 로그인 상태를 확인하세요.');
  } else if (response.statusCode == 403) {
    throw Exception('권한 없음: 서버 권한 확인 필요.');
  } else {
    throw Exception('업로드 실패: ${response.statusCode} ${response.body}');
  }
}
