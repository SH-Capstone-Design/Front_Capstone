import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


class CreateCodeScreen extends StatefulWidget {
  const CreateCodeScreen({Key? key}) : super(key: key);

  @override
  State<CreateCodeScreen> createState() => _CreateCodeScreenState();
}

class _CreateCodeScreenState extends State<CreateCodeScreen> {
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

    final response = await http.post(
      Uri.parse('${dotenv.env['BASE_URL']}/couples/code'),
      headers: {'Content-Type': 'application/json'},
    );
    print('응답 바디: ${response.body}');


    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      setState(() {
        _code = json['code'];
        _isLoading = false;
      });
    } else {
      setState(() {
        _code = '생성 실패';
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('코드 생성 실패')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('커플 코드 생성'),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _code != null
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '생성된 커플 코드:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SelectableText(
              _code!,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _code!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('코드가 복사되었습니다!')),
                );
              },
              child: const Text('코드 복사'),
            ),
          ],
        )
            : const Text('코드를 불러오지 못했습니다.'),
      ),
    );
  }
}
