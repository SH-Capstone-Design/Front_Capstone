// screens/create_code_screen.dart
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
import '../widgets/rounded_button.dart';

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

    /// WebSocket 이벤트 리스너 등록
    CodeWebsocketService.setOnCoupleConnected((event) {
      final message = event['payload']?['message'] ?? '커플 연결 성공!';
      messengerKey.currentState?.showSnackBar(SnackBar(content: Text(message)));
    });

    /// WebSocket 연결 + 코드 생성
    _initialize();
  }

  Future<void> _initialize() async {
    final token = await AuthService.getToken();
    final userId = await AuthService.getUserId();

    if (token == null || userId == null) {
      setState(() {
        _code = '토큰 또는 사용자 ID 없음';
        _isLoading = false;
      });
      return;
    }

    // STOMP 연결
    await CodeWebsocketService.connect(userId, token);

    // 연결 후 코드 생성
    await _fetchCoupleCode(token);
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenHeight = size.height;
    final screenWidth = size.width;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFE6F3), Color(0xFFFDE6FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          image: DecorationImage(
            image: AssetImage(AppConstants.backgroundPath),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.05),
              Image.asset(AppConstants.logoPath, height: screenHeight * 0.15),
              SizedBox(height: screenHeight * 0.02),
              Text(
                '상대방과 연결을 위한 코드를 만들었어요',
                style: TextStyle(
                  fontFamily: 'GowunBatang',
                  fontSize: screenHeight * 0.02,
                  color: Colors.black87,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                    top: screenHeight * 0.02, bottom: screenHeight * 0.03),
                child: Image.asset(
                  "assets/images/hello.png",
                  width: screenWidth * 0.4,
                  height: screenHeight * 0.2,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                child: Text(
                  '아래의 코드를 상대방에게 전달하면,\n두 사람이 연결됩니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'GowunBatang',
                    fontSize: screenHeight * 0.018,
                    color: Colors.black54,
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: screenHeight * 0.03),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDEEFF),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pinkAccent.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : Column(
                      children: [
                        Text(
                          '초대 코드',
                          style: TextStyle(
                            fontFamily: 'GowunBatang',
                            fontSize: screenHeight * 0.022,
                            color: Colors.black54,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.015),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _code ?? '생성 중...',
                              style: TextStyle(
                                fontFamily: 'GowunBatang',
                                fontSize: screenHeight * 0.03,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.03),
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
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                child: RoundedButton(
                  text: '돌아가기',
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              SizedBox(height: screenHeight * 0.04),
              Padding(
                padding: EdgeInsets.only(bottom: screenHeight * 0.03),
                child: Text(
                  '당신의 코드로 사랑이 시작됩니다.',
                  style: TextStyle(
                    fontFamily: 'GowunBatang',
                    fontSize: screenHeight * 0.017,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
