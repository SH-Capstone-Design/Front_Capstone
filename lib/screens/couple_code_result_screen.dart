import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/jwt_token_provider.dart';
import '../services/api_service.dart';
import 'package:flutter/services.dart';

class CoupleCodeResultScreen extends ConsumerStatefulWidget {
  final String code;
  const CoupleCodeResultScreen({Key? key, required this.code}) : super(key: key);

  @override
  ConsumerState<CoupleCodeResultScreen> createState() => _CoupleCodeResultScreenState();
}

class _CoupleCodeResultScreenState extends ConsumerState<CoupleCodeResultScreen> {
  String? _coupleCode;
  bool _isLoading = true;
  String? _error;

  // ApiService 인스턴스 (주소는 프로젝트에 맞게!)
  final ApiService _apiService = ApiService(baseUrl: 'http://18.119.138.97:8080');

  @override
  void initState() {
    super.initState();
    _fetchCoupleCode();
  }

  Future<void> _fetchCoupleCode() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // JWT 토큰을 Provider에서 읽어옴
      final jwtToken = ref.read(jwtTokenProvider);
      if (jwtToken == null) throw Exception("로그인 정보 없음(토큰 없음)");

      final code = await _apiService.generateCoupleCode(jwtToken: jwtToken);
      setState(() {
        _coupleCode = code;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _copyCode() {
    if (_coupleCode == null) return;
    Clipboard.setData(ClipboardData(text: _coupleCode!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('코드가 복사되었습니다!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8FC),
      appBar: AppBar(
        title: const Text('커플 코드', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: Center(
          child: _isLoading
              ? const CircularProgressIndicator()
              : _error != null
              ? Text(
            '오류: $_error',
            style: const TextStyle(color: Colors.red),
          )
              : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 로고 이미지
              Container(
                padding: const EdgeInsets.all(32),
                margin: const EdgeInsets.only(bottom: 40),
                color: Colors.white,
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 48,
                  fit: BoxFit.contain,
                ),
              ),
              const Text('생성된 커플 코드', style: TextStyle(fontSize: 20)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _coupleCode ?? '',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _copyCode,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.07),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        "복사",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
