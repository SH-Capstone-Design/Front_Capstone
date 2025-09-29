import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectbeat/services/api_service.dart';
import 'package:image_picker/image_picker.dart';

class UserNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  UserNotifier() : super(const AsyncValue.loading()) {
    fetchUser();
  }

  /// 사용자 정보 불러오기
  Future<void> fetchUser() async {
    try {
      state = const AsyncValue.loading();
      final user = await ApiService.fetchUserInfo();
      if (user != null) {
        state = AsyncValue.data(user);
      } else {
        state = AsyncValue.error('사용자 정보 없음', StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
    }
  }

  /// 사용자 정보 업데이트
  Future<void> updateUser({
    required String nickname,
    String? profileImage,
  }) async {
    try {
      final updatedUser = await ApiService.updateUserInfo(
        nickname: nickname,
        profileImage: profileImage,
      );

      // 서버가 빈 응답을 보내도 기존 사용자 정보 유지
      if (updatedUser != null) {
        state = AsyncValue.data(updatedUser);
      }
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
      rethrow;
    }
  }

  /// 갤러리에서 이미지 선택
  Future<File?> pickImageFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      return File(picked.path);
    }
    return null;
  }

  /// 상태 강제로 설정 (optional)
  void setUser(Map<String, dynamic> user) {
    state = AsyncValue.data(user);
  }
}

final userProvider =
StateNotifierProvider<UserNotifier, AsyncValue<Map<String, dynamic>>>(
      (ref) => UserNotifier(),
);
