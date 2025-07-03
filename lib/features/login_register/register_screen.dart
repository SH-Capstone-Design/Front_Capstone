import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import 'widgets/email_input.dart';
import 'widgets/password_input.dart';
import 'widgets/register_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  final AuthService authService = AuthService();

  Future<void> _register() async {
    FocusScope.of(context).unfocus();

    if (emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty ||
        confirmController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 필드를 입력해 주세요')),
      );
      return;
    }


    if (passwordController.text != confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호가 일치하지 않습니다')),
      );
      return;
    }

    try {
      final token = await authService.requestRegisterToken(
        emailController.text.trim(),
        passwordController.text,
      );

      if (token != null) {
        print('회원가입 성공, 토큰: $token');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원가입 성공!')),
        );
        // 회원가입 성공 후 화면 이동 등 처리 여기에 추가 가능
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원가입 실패')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류 발생: $e')),
      );
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "회원가입",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Connect Beat",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 32),
              EmailInput(controller: emailController),
              const SizedBox(height: 16),
              PasswordInput(controller: passwordController),
              const SizedBox(height: 16),
              PasswordInput(controller: passwordController),
              const SizedBox(height: 32),
              RegisterButton(onPressed: _register),
            ],
          ),
        ),
      ),
    );
  }
}
