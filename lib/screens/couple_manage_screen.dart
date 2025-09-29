import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:connectbeat/core/constants.dart';
import '../widgets/rounded_button.dart';
import '../services/auth_service.dart';

class CoupleManageScreen extends StatelessWidget {
  const CoupleManageScreen({super.key});

  /// 내 커플 상태 조회
  Future<Map<String, dynamic>> fetchCoupleStatus() async {
    final url = Uri.parse('${dotenv.env['BASE_URL']}/couples/status');
    final token = await AuthService.getToken();

    if (token == null) {
      throw Exception("JWT 토큰이 없습니다. 로그인 후 다시 시도해주세요.");
    }

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else if (response.statusCode == 401) {
      throw Exception("인증 실패. 로그인 후 다시 시도해주세요.");
    } else {
      throw Exception("커플 상태 조회 실패 (${response.statusCode})");
    }
  }

  /// 커플 해제 요청
  Future<void> unlinkCouple(BuildContext context) async {
    final url = Uri.parse('${dotenv.env['BASE_URL']}/couples/unlink');
    final token = await AuthService.getToken();

    if (token == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "로그인이 필요합니다.",
              style: TextStyle(fontFamily: 'GamjaFlower'),
            ),
          ),
        );
      }
      return;
    }

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "커플이 해제되었습니다.",
              style: TextStyle(fontFamily: 'GamjaFlower'),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "커플 해제에 실패했습니다. (${response.statusCode})",
              style: const TextStyle(fontFamily: 'GamjaFlower'),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const titleFontSize = 22.0;
    const infoFontSize = 18.0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          '커플 관리',
          style: TextStyle(
              fontFamily: 'GowunBatang', fontSize: titleFontSize, color: Colors.black),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppConstants.backgroundPath),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: FutureBuilder<Map<String, dynamic>>(
              future: fetchCoupleStatus(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      snapshot.error.toString(),
                      style: const TextStyle(
                        color: Colors.red,
                        fontFamily: 'GowunBatang',
                      ),
                    ),
                  );
                }

                final data = snapshot.data!;
                final status = data['status'] ?? 'NONE';
                final partnerNickname = data['partnerNickname'] ?? '-';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 80),
                    Text(
                      '커플 상태: $status',
                      style: const TextStyle(
                        fontFamily: 'GowunBatang',
                        fontSize: infoFontSize,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '파트너: $partnerNickname',
                      style: const TextStyle(
                        fontFamily: 'GowunBatang',
                        fontSize: infoFontSize - 2,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 24),
                    RoundedButton(
                      text: '커플 해제',
                      onPressed: () => unlinkCouple(context),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
