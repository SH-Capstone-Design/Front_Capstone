import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/couple_code_repository.dart';

final coupleCodeProvider = StateNotifierProvider<CoupleCodeNotifier, AsyncValue<String>>((ref) {
  final repo = ref.read(coupleCodeRepositoryProvider);
  return CoupleCodeNotifier(repo);
});

class CoupleCodeNotifier extends StateNotifier<AsyncValue<String>> {
  final CoupleCodeRepository repository;
  CoupleCodeNotifier(this.repository) : super(const AsyncValue.data(''));

  Future<void> generateCode() async {
    state = const AsyncValue.loading();
    try {
      final code = await repository.generateCoupleCode();
      state = AsyncValue.data(code);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
