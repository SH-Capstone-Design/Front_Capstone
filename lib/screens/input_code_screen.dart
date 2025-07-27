import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectbeat/core/constants.dart';
import '../../../widgets/rounded_button.dart';
import 'package:connectbeat/providers/input_code_provider.dart';

class InputCodeScreen extends ConsumerWidget {
  const InputCodeScreen({super.key});

  Future<bool> checkCodeInDatabase(String code) async {
    await Future.delayed(const Duration(seconds: 1));
    const dummyCodesInDB = ['ABCD123', 'CONNECTBEAT1'];
    return dummyCodesInDB.contains(code.trim().toUpperCase());
  }

  void _submitCode(WidgetRef ref, BuildContext context) async {
    final code = ref.read(codeInputProvider).trim().toUpperCase();

    if (code.isEmpty) {
      ref.read(codeErrorProvider.notifier).state = '코드를 입력해주세요.';
      return;
    }

    ref.read(codeLoadingProvider.notifier).state = true;
    ref.read(codeErrorProvider.notifier).state = null;

    final isValid = await checkCodeInDatabase(code);
    ref.read(codeLoadingProvider.notifier).state = false;

    if (isValid) {
      Navigator.pushNamed(context, '/home-screen');
    } else {
      ref.read(codeErrorProvider.notifier).state = '유효하지 않은 코드입니다.';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final isLoading = ref.watch(codeLoadingProvider);
    final errorMessage = ref.watch(codeErrorProvider);

    final textFieldHeight = screenHeight * 0.05;

    final logoHeight = screenHeight * 0.2;

    final topPadding = size.height * 0.01;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppConstants.backgroundPath),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: topPadding),

                // 앱 로고
                SizedBox(
                  height: logoHeight,
                  child: Image.asset(
                    AppConstants.logoPath,
                    fit: BoxFit.contain,
                  ),
                ),

                const Spacer(flex: 2),

                // 코드 입력 필드
                Container(
                  height: textFieldHeight,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    onChanged: (value) => ref.read(codeInputProvider.notifier).state = value,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      hintText: '코드 입력칸',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    style: TextStyle(fontSize: screenHeight * 0.022),
                  ),
                ),

                if (errorMessage != null) ...[
                  SizedBox(height: screenHeight * 0.01),
                  Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ],

                SizedBox(height: screenHeight * 0.03),

                // 확인 버튼
                RoundedButton(
                  text: '코드 확인',
                  onPressed: isLoading ? null : () => _submitCode(ref, context),
                ),

                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
