// lib/services/s3_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_service.dart';

/// 🔹 File 업로드
Future<String> uploadProfileImageToServer(File imageFile) async {
  final token = await AuthService.getToken();

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
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    return data['profileImageUrl'];
  } else {
    throw Exception('업로드 실패: ${response.statusCode} ${response.body}');
  }
}

/// 🔹 URL을 통해 가져온 이미지를 업로드
Future<String> uploadProfileImageFromUrl(String imageUrl) async {
  final response = await http.get(Uri.parse(imageUrl));
  final tempDir = Directory.systemTemp;
  final file = File('${tempDir.path}/temp_profile_${DateTime.now().millisecondsSinceEpoch}.jpg');
  await file.writeAsBytes(response.bodyBytes);

  return await uploadProfileImageToServer(file);
}
