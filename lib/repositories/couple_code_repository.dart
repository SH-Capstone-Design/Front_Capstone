import 'package:flutter_riverpod/flutter_riverpod.dart';

final coupleCodeRepositoryProvider = Provider<CoupleCodeRepository>((ref) {
  return CoupleCodeRepositoryImpl();
});

abstract class CoupleCodeRepository {
  Future<String> generateCoupleCode();
}

class CoupleCodeRepositoryImpl implements CoupleCodeRepository {
  @override
  Future<String> generateCoupleCode() async {
    // 실제 API 호출 코드 (예시)
    // await Future.delayed(const Duration(seconds: 1));
    // return "A1B2C3";
    // ↓ 아래는 http 패키지 예시
    // final response = await http.post(...);
    // return response.body['code'];
    // 아래는 임시 코드
    await Future.delayed(const Duration(seconds: 1));
    return "A1B2C3";
  }
}
