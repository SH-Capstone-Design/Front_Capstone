import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectbeat/core/constants.dart';
import 'package:connectbeat/widgets/rounded_button.dart';
import 'package:connectbeat/providers/input_code_provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:connectbeat/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final String baseUrl = dotenv.env['BASE_URL']!;

class InputCodeScreen extends ConsumerStatefulWidget {
  const InputCodeScreen({super.key});

  @override
  ConsumerState<InputCodeScreen> createState() => _InputCodeScreenState();
}

class _InputCodeScreenState extends ConsumerState<InputCodeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<String?> _connectCouple(String code) async {
    final token = await AuthService.getToken();
    if (token == null) return '로그인이 필요합니다.';

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/couples/link'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'code': code}),
      );

      print("🧩 Response status: ${response.statusCode}");
      print("🧩 Response body: ${response.body}");

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isCoupleConnected', true);
        await prefs.setString('coupleCode', code);
        return null;
      } else if (response.statusCode == 400) {
        final body = jsonDecode(response.body);
        return body['error'] ?? '유효하지 않은 코드입니다.';
      } else if (response.statusCode == 404) {
        return '해당 코드를 찾을 수 없습니다.';
      } else {
        return '서버 오류 (${response.statusCode})';
      }
    } catch (e) {
      return '네트워크 오류가 발생했습니다.';
    }
  }

  void _submitCode() async {
    final code = ref.read(codeInputProvider).trim();
    if (code.isEmpty) {
      ref.read(codeErrorProvider.notifier).state = '코드를 입력해주세요.';
      return;
    }

    ref.read(codeLoadingProvider.notifier).state = true;
    ref.read(codeErrorProvider.notifier).state = null;

    final errorMsg = await _connectCouple(code);
    ref.read(codeLoadingProvider.notifier).state = false;

    if (errorMsg == null) {
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } else {
      ref.read(codeErrorProvider.notifier).state = errorMsg;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenHeight = size.height;
    final screenWidth = size.width;
    final isLoading = ref.watch(codeLoadingProvider);
    final errorMessage = ref.watch(codeErrorProvider);

    return Scaffold(
      body: Stack(
        children: [
          // 🌸 배경 이미지
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(AppConstants.backgroundPath),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 💌 카드 본문
          Center(
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                width: screenWidth * 0.85,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.07,
                  vertical: screenHeight * 0.045,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 로고
                    Image.asset(
                      AppConstants.logoPath,
                      height: screenHeight * 0.12,
                    ),
                    SizedBox(height: screenHeight * 0.025),

                    Text(
                      '상대방에게 받은 코드를 입력하세요',
                      style: TextStyle(
                        fontFamily: 'GowunBatang',
                        fontSize: screenHeight * 0.02,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenHeight * 0.03),

                    // 코드 입력창
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFFDAAFF),
                          width: 1.4,
                        ),
                      ),
                      child: TextField(
                        onChanged: (value) =>
                        ref.read(codeInputProvider.notifier).state = value,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: '예: connect123',
                        ),
                        style: TextStyle(
                          fontFamily: 'GowunBatang',
                          fontSize: screenHeight * 0.022,
                          color: Colors.black87,
                        ),
                      ),
                    ),

                    if (errorMessage != null) ...[
                      SizedBox(height: screenHeight * 0.015),
                      Text(
                        errorMessage,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontFamily: 'GowunBatang',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],

                    SizedBox(height: screenHeight * 0.05),

                    // 버튼
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFDAAFF), Color(0xFFFFE6F3)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pinkAccent.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: RoundedButton(
                        text: isLoading ? '연결 중...' : '커플 연결하기',
                        onPressed: isLoading ? null : _submitCode,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),


                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pinkAccent.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: RoundedButton(
                        text: '돌아가기',
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
