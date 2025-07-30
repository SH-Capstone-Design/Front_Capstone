import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectbeat/core/constants.dart';
// import '../../../widgets/rounded_button.dart';
import 'package:connectbeat/widgets/rounded_button.dart';  // ✅ 경로 수정
import 'package:connectbeat/providers/input_code_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:connectbeat/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ 추가

final String baseUrl = dotenv.env['BASE_URL']!;

class InputCodeScreen extends ConsumerWidget {
  const InputCodeScreen({super.key});

  Future<String?> _connectCouple(String code) async {
    final token = await AuthService.getToken();
    if (token == null) return '로그인이 필요합니다.';

    try {
      final String linkUrl = '$baseUrl/couples/link';

      final response = await http.post(
        Uri.parse(linkUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'code': code}),
      );

      if (response.statusCode == 200) {
        return null;
      } else if (response.statusCode == 400) {
        final body = jsonDecode(response.body);
        return body['error'] ?? '유효하지 않은 코드입니다.';
      } else {
        return '서버 오류가 발생했습니다. (${response.statusCode})';
      }
    } catch (e) {
      return '네트워크 오류가 발생했습니다.';
    }
  }

  void _submitCode(WidgetRef ref, BuildContext context) async {
    final code = ref.read(codeInputProvider).trim();

    if (code.isEmpty) {
      ref.read(codeErrorProvider.notifier).state = '코드를 입력해주세요.';
      return;
    }

    ref.read(codeLoadingProvider.notifier).state = true;
    ref.read(codeErrorProvider.notifier).state = null;

    if (code == 'connectbeat') {
      // ✅ 마스터 코드 처리
      await Future.delayed(const Duration(milliseconds: 500));
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isCoupleConnected', true);
        await prefs.setString('coupleCode', 'connectbeat');
      } catch (e) {
        ref.read(codeErrorProvider.notifier).state = '저장 중 오류 발생: $e';
        ref.read(codeLoadingProvider.notifier).state = false;
        return;
      }

      ref.read(codeLoadingProvider.notifier).state = false;
      Navigator.pushNamed(context, '/home-screen');
      return;
    }

    // 일반 커플 코드 처리
    final errorMsg = await _connectCouple(code);
    ref.read(codeLoadingProvider.notifier).state = false;

    if (errorMsg == null) {
      Navigator.pushNamed(context, '/home-screen');
    } else {
      ref.read(codeErrorProvider.notifier).state = errorMsg;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    final screenHeight = size.height;
    final screenWidth = size.width;

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

                SizedBox(
                  height: logoHeight,
                  child: Image.asset(
                    AppConstants.logoPath,
                    fit: BoxFit.contain,
                  ),
                ),

                const Spacer(flex: 2),

                Container(
                  height: textFieldHeight,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    onChanged: (value) =>
                    ref.read(codeInputProvider.notifier).state = value,
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
                    textAlign: TextAlign.center,
                  ),
                ],

                SizedBox(height: screenHeight * 0.03),

                RoundedButton(
                  text: '코드 확인',
                  onPressed:
                  isLoading ? null : () => _submitCode(ref, context),
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
