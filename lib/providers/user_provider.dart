// lib/providers/user_provider.dart
import 'dart:io';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class UserNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  UserNotifier() : super(const AsyncValue.loading()) {
    fetchUser();
  }

  /// 🔹 현재 사용자 정보 조회
  Future<void> fetchUser() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('JWT 토큰 없음');

      final response = await http.get(
        Uri.parse('${dotenv.env['BASE_URL']}/users/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        state = AsyncValue.data(data);
      } else {
        throw Exception('사용자 조회 실패 (${response.statusCode})');
      }
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
    }
  }

  /// 🔹 닉네임 수정
  Future<void> updateNickname(String nickname) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('JWT 토큰 없음');

      final response = await http.put(
        Uri.parse('${dotenv.env['BASE_URL']}/users/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'nickname': nickname}),
      );

      if (response.statusCode == 200) {
        final current = state.value ?? {};
        final updated = {...current, 'nickname': nickname};
        state = AsyncValue.data(updated);
      } else {
        throw Exception('닉네임 수정 실패 (${response.statusCode})');
      }
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
      rethrow;
    }
  }

  /// 🔹 프로필 이미지 업로드
  Future<String?> uploadProfileImage(File imageFile) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('JWT 토큰 없음');

      final uri = Uri.parse('${dotenv.env['BASE_URL']}/users/me/profile-image');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
      final parts = mimeType.split('/');

      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        contentType: MediaType(parts[0], parts[1]),
      ));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(responseBody.codeUnits));
        final newUrl = data['profileImageUrl'];

        final current = state.value ?? {};
        final updated = {...current, 'profileImage': newUrl};
        state = AsyncValue.data(updated);

        return newUrl;
      } else {
        throw Exception('이미지 업로드 실패 (${response.statusCode})');
      }
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
      rethrow;
    }
  }

  /// 🔹 갤러리에서 이미지 선택
  Future<File?> pickImageFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      return File(picked.path);
    }
    return null;
  }
}

final userProvider =
StateNotifierProvider<UserNotifier, AsyncValue<Map<String, dynamic>>>(
      (ref) => UserNotifier(),
);
