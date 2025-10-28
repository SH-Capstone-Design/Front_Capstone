// lib/providers/user_provider.dart
import 'dart:io';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/auth_service.dart';
import 'package:connectbeat/services/s3_service.dart' as s3;
import 'package:image_picker/image_picker.dart';

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
    final current = state.value ?? {};
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
        state = AsyncValue.data({...current, 'nickname': nickname});
      } else {
        throw Exception('닉네임 수정 실패 (${response.statusCode})');
      }
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
      rethrow;
    }
  }

  /// 🔹 프로필 이미지 업로드 (File)
  Future<String?> uploadProfileImage(File imageFile) async {
    try {
      final newUrl = await s3.uploadProfileImageToServer(imageFile);
      final current = state.value ?? {};
      state = AsyncValue.data({...current, 'profileImage': newUrl});
      return newUrl;
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
      rethrow;
    }
  }

  /// 🔹 프로필 이미지 업로드 (URL)
  Future<String?> uploadProfileImageFromUrl(String imageUrl) async {
    try {
      // s3_service의 함수를 사용하여 URL 이미지 업로드
      final newUrl = await s3.uploadProfileImageFromUrl(imageUrl);
      final current = state.value ?? {};
      state = AsyncValue.data({...current, 'profileImage': newUrl});
      return newUrl;
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
      rethrow;
    }
  }

  /// 🔹 갤러리에서 이미지 선택
  Future<File?> pickImageFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) return File(picked.path);
    return null;
  }
}

/// 🔹 UserProvider 정의
final userProvider =
StateNotifierProvider<UserNotifier, AsyncValue<Map<String, dynamic>>>(
        (ref) => UserNotifier());
