import 'package:flutter/material.dart';

class EmailInput extends StatelessWidget {
  final TextEditingController controller;

  const EmailInput({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(
        labelText: '이메일',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.email),
      ),
    );
  }
}
