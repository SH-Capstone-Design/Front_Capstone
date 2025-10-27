import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:connectbeat/services/auth_service.dart';
import 'package:connectbeat/services/code_websocket_service.dart';
import 'package:http/http.dart' as http;
import 'package:connectbeat/core/constants.dart';
import 'package:connectbeat/main.dart';

class CreateCodeScreen extends StatefulWidget {
  const CreateCodeScreen({super.key});

  @override
  State<CreateCodeScreen> createState() => _CreateCodeScreenState();
}

class _CreateCodeScreenState extends State<CreateCodeScreen> {
  String? _code;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebSocketAndFetchCode();
  }

  @override
  void dispose() {
    CodeWebsocketService.disconnect();
    super.dispose();
  }

  Future<void> _initializeWebSocketAndFetchCode() async {
    final token = await AuthService.getToken();
    final userId = await AuthService.getUserId();

    if (token == null || userId == null) {
      setState(() {
        _code = '토큰 또는 사용자 ID 없음';
        _isLoading = false;
      });
      return;
    }

    // 1️⃣ WebSocket 연결
    await CodeWebsocketService.connect(
      userId,
      token,
      onSubscribed: () {
        print("📌 WebSocket 구독 완료, 이제 코드 생성 호출 가능");

        // 2️⃣ 커플 코드 생성
        _fetchCoupleCode(token);

        // 3️⃣ WebSocket 이벤트 수신 시 화면 전환 처리
        CodeWebsocketService.setOnCoupleConnected((event) {
          final message = event['payload']?['message'] ?? '커플 연결 성공!';
          navigatorKey.currentState?.pushReplacementNamed('/home');
          messengerKey.currentState?.showSnackBar(
            SnackBar(content: Text(message)),
          );
        });
      },
    );
  }

  Future<void> _fetchCoupleCode(String token) async {
    setState(() => _isLoading = true);

    try {
      final baseUrl = dotenv.env['BASE_URL']!;
      final response = await http.post(
        Uri.parse('$baseUrl/couples/code'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({}),
      );

      print("🛠 Response status: ${response.statusCode}");
      print("🛠 Response body: ${response.body}");

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final jsonBody = jsonDecode(decodedBody);
        final code = jsonBody['code'];

        setState(() {
          _code = code;
          _isLoading = false;
        });
      } else {
        setState(() {
          _code = '생성 실패';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _code = '에러 발생';
        _isLoading = false;
      });
      print("❌ _fetchCoupleCode 에러: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final logoHeight = screenHeight * 0.2;

    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset(
              AppConstants.backgroundPath,
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: screenHeight * 0.03),
                  SizedBox(
                    height: logoHeight,
                    child: Image.asset(
                      AppConstants.logoPath,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const Spacer(flex: 2),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.06,
                      vertical: screenHeight * 0.02,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDEEFF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '코드 : $_code',
                            style: TextStyle(
                              fontFamily: 'GowunBatang',
                              fontSize: screenHeight * 0.025,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          GestureDetector(
                            onTap: () {
                              if (_code != null) {
                                Clipboard.setData(
                                    ClipboardData(text: _code!));
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      '코드가 복사되었습니다!',
                                      style: TextStyle(
                                        fontFamily: 'GowunBatang',
                                      ),
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Text(
                              '복사',
                              style: TextStyle(
                                fontFamily: 'GowunBatang',
                                fontSize: screenHeight * 0.022,
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(flex: 3),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
