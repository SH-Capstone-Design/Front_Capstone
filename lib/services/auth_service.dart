import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static final _storage = FlutterSecureStorage();

  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: 'jwt_token');
  }

  // 구글 idToken 저장
  static Future<void> saveGoogleIdToken(String idToken) async {
    await _storage.write(key: 'google_id_token', value: idToken);
  }

  // 구글 idToken 불러오기
  static Future<String?> getGoogleIdToken() async {
    return await _storage.read(key: 'google_id_token');
  }

  // 구글 idToken 삭제
  static Future<void> deleteGoogleIdToken() async {
    await _storage.delete(key: 'google_id_token');
  }
}
