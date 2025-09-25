import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import 'package:image_picker/image_picker.dart';

/// 유저 상태 관리 Notifier (UserModel 없이 Map 사용)
class UserNotifier extends StateNotifier<Map<String, dynamic>?> {
  final Ref ref;
  final ImagePicker _picker = ImagePicker();

  UserNotifier(this.ref) : super(null);

  /// 서버에서 유저 정보 가져오기
  Future<void> fetchUser() async {
    final response = await ApiService.getWithAuth('/users/me');

    if (response.statusCode == 200 && response.body.isNotEmpty) {
      final data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      state = data;
    } else {
      throw Exception('사용자 정보 불러오기 실패: ${response.statusCode} ${response.body}');
    }
  }

  /// 닉네임/프로필 업데이트
  Future<void> updateUser({String? nickname, String? profileImage}) async {
    final body = <String, dynamic>{};
    if (nickname != null) body['nickname'] = nickname;
    if (profileImage != null) body['profileImage'] = profileImage;

    final response = await ApiService.putWithAuth('/users/me', body: body);

    if (response.statusCode == 200) {
      if (response.body.isNotEmpty) {
        final data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        state = data; // 서버에서 새 유저 정보를 준 경우 업데이트
      } else {
        // 서버가 빈 응답을 돌려주면, 기존 상태를 로컬에서 갱신
        state = {
          ...?state,
          if (nickname != null) "nickname": nickname,
          if (profileImage != null) "profileImage": profileImage,
        };
      }
    } else {
      throw Exception('유저 정보 업데이트 실패: ${response.statusCode} ${response.body}');
    }
  }

  /// 갤러리에서 이미지 선택
  Future<File?> pickImageFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  /// 로컬에서 임시 상태 변경
  void setUser(Map<String, dynamic> user) {
    state = user;
  }
}

/// StateNotifierProvider
final userProvider = StateNotifierProvider<UserNotifier, Map<String, dynamic>?>(
      (ref) => UserNotifier(ref),
);
