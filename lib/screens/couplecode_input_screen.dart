
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final coupleCodeProvider = StateProvider<String>((ref) => '123456'); // 예시: 서버에서 받아오는 커플 코드

class CoupleCodeInputScreen extends ConsumerStatefulWidget {
  const CoupleCodeInputScreen({super.key});

  @override
  ConsumerState<CoupleCodeInputScreen> createState() => _CoupleCodeInputScreenState();
}

class _CoupleCodeInputScreenState extends ConsumerState<CoupleCodeInputScreen> {
  final TextEditingController _codeController = TextEditingController();
  String? _error;

  void _onConfirmPressed(BuildContext context) {
    final inputCode = _codeController.text.trim();
    final coupleCode = ref.read(coupleCodeProvider);

    if (inputCode == coupleCode) {
      // 코드가 맞을 때 home_screen.dart로 이동
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      // 에러 메시지 표시
      setState(() {
        _error = '코드가 일치하지 않습니다.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8FC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 흰색 박스 + 로고
                Image.asset(
                  'assets/images/logo.png',
                  height: 48,
                  fit: BoxFit.contain,
                ),

                // 코드 입력 텍스트필드
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE5F3),
                    borderRadius: BorderRadius.circular(16),
                  ),

                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: TextField(
                      controller: _codeController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: '코드 입력칸',
                      ),
                      textAlign: TextAlign.center,

                    ),
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                // 코드 확인 버튼
                GestureDetector(
                  onTap: () => _onConfirmPressed(context),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 24),
                    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE5F3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      '코드 확인',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
