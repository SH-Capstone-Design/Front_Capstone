import 'package:flutter/material.dart';

class PasswordInput extends StatelessWidget {
  final TextEditingController controller;

  const PasswordInput({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: true,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      enableSuggestions: false,
      decoration: const InputDecoration(
        labelText: '비밀번호',
        prefixIcon: Icon(Icons.lock),
        border: OutlineInputBorder(),
      ),
    );
  }
}
