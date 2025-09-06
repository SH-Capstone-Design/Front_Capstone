import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:connectbeat/core/constants.dart';
import '../widgets/rounded_button.dart';

class CoupleManageScreen extends StatelessWidget {
  const CoupleManageScreen({super.key});

  // 커플 코드 가져오기
  Future<String> fetchCoupleCode() async {
    final url = Uri.parse('${dotenv.env['BASE_URL']}/couples/me');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['code'] as String; // 응답에서 code 값 추출
    } else {
      throw Exception("Failed to load couple code");
    }
  }

  // 커플 해제 요청
  Future<void> unlinkCouple(BuildContext context) async {
    final url = Uri.parse('${dotenv.env['BASE_URL']}/couples/unlink');
    final response = await http.post(url);

    if (response.statusCode == 200) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("커플이 해제되었습니다.")),
        );
        Navigator.pop(context);
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("커플 해제에 실패했습니다.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppConstants.backgroundPath),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 뒤로가기 버튼
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                const SizedBox(height: 8),

                // 제목
                const Text(
                  '커플 관리',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 48),

                // 커플 코드
                FutureBuilder<String>(
                  future: fetchCoupleCode(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    if (snapshot.hasError) {
                      return const Text(
                        '코드를 불러오지 못했습니다',
                        style: TextStyle(color: Colors.red),
                      );
                    }
                    final code = snapshot.data ?? '-';
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.pink.shade50,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '커플 코드',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            code,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // 커플 해제 버튼
                RoundedButton(
                  text: '커플 해제',
                  onPressed: () => unlinkCouple(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
