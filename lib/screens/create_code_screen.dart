import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:connectbeat/core/constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:connectbeat/services/auth_service.dart';

class CreateCodeScreen extends ConsumerStatefulWidget {
  const CreateCodeScreen({super.key});

  @override
  ConsumerState<CreateCodeScreen> createState() => _CreateCodeScreenState();
}

class _CreateCodeScreenState extends ConsumerState<CreateCodeScreen> {
  String? _code;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCoupleCode();
  }

  Future<void> _fetchCoupleCode() async {
    setState(() {
      _isLoading = true;
    });

    final token = await AuthService.getToken();
    if (token == null) {
      setState(() {
        _code = '토큰 없음';
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${dotenv.env['BASE_URL']}/couples/code'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({}),
      );

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final json = jsonDecode(decodedBody);
        final code = json['code'];
        final message = json['message'];

        setState(() {
          _code = code;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message ?? '코드가 생성되었습니다',
              style: const TextStyle(fontFamily: 'GowunBatang'),
            ),
          ),
        );
      } else {
        setState(() {
          _code = '생성 실패';
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '코드 생성 실패: ${response.body}',
              style: const TextStyle(fontFamily: 'GowunBatang'),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _code = '에러 발생';
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '에러: $e',
            style: const TextStyle(fontFamily: 'GowunBatang'),
          ),
        ),
      );
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
          // 배경 이미지
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
                                          fontFamily: 'GowunBatang'),
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
