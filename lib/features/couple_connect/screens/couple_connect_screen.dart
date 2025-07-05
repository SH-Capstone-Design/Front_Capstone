import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/common/rounded_button.dart';
import '../../../providers/couple_code_provider.dart';
import '../../../screens/couple_code_result_screen.dart';

class CoupleConnectScreen extends ConsumerWidget {
  const CoupleConnectScreen({super.key});

  // 비동기 버튼 콜백은 별도 메서드로!
  Future<void> _onCreateCode(BuildContext context, WidgetRef ref) async {
    await ref.read(coupleCodeProvider.notifier).generateCode();
    final value = ref.read(coupleCodeProvider).value;
    if (value != null && value.isNotEmpty) {
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CoupleCodeResultScreen(code: value),
          ),
        );
      }
    }
    // else: 에러 상황 핸들링 필요 시 여기에!
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coupleCodeState = ref.watch(coupleCodeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 40),
                margin: const EdgeInsets.only(bottom: 60),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 48,
                  fit: BoxFit.contain,
                ),
              ),
              RoundedButton(
                text: '커플 코드 생성',
                onPressed: coupleCodeState.isLoading
                    ? null
                    : () {
                  _onCreateCode(context, ref);
                },
              ),


              const SizedBox(height: 20),
              RoundedButton(
                text: '커플 코드 입력',
                onPressed: () {
                  // TODO: 커플 코드 입력 기능 연결
                },
              ),
              if (coupleCodeState.isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: CircularProgressIndicator(),
                ),
              if (coupleCodeState.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Text(
                    '코드 생성에 실패했습니다.',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
