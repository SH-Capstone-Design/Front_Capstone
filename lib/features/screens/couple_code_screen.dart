import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';

class CoupleCodeScreen extends StatefulWidget {
  const CoupleCodeScreen({Key? key}) : super(key: key);

  @override
  State<CoupleCodeScreen> createState() => _CoupleCodeScreenState();
}

class _CoupleCodeScreenState extends State<CoupleCodeScreen> {
  String? _coupleCode;
  bool _isLoading = true;

  @override
  void initState() {  // API호출
    super.initState();
    _fetchCoupleCode();
  }

  Future<void> _fetchCoupleCode() async {
    // 실제로는 JWT 인증 토큰 필요! (여기선 예시)
    const url = 'https://your-backend-url.com/api/couples/code';
    final response = await http.post(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        // "Authorization": "Bearer $jwtToken",  // JWT 토큰 필요 시
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _coupleCode = data['code'];
        _isLoading = false;
      });
    } else {
      setState(() {
        _coupleCode = "ERROR";
        _isLoading = false;
      });
    }
  }

  void _copyCode() {
    if (_coupleCode != null) {
      // 클립보드에 복사
      Clipboard.setData(ClipboardData(text: _coupleCode!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("코드가 복사되었습니다!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Colors.black),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo 이미지
              Container(
                padding: const EdgeInsets.all(32),
                margin: const EdgeInsets.only(bottom: 60),
                color: Colors.white,
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 48,
                  fit: BoxFit.contain,
                ),
              ),
              _isLoading
                  ? const CircularProgressIndicator()
                  : Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 18),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCE9F2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "코드 : ${_coupleCode ?? ''}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _copyCode,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "복사",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
