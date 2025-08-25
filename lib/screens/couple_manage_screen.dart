import 'package:flutter/material.dart';
import 'package:connectbeat/core/constants.dart';
import '../widgets/rounded_button.dart';
import 'package:http/http.dart' as http;

class CoupleManageScreen extends StatefulWidget {
  final String initialCoupleCode; // DB에서 가져온 커플 코드 전달

  const CoupleManageScreen({super.key, required this.initialCoupleCode});

  @override
  State<CoupleManageScreen> createState() => _CoupleManageScreenState();
}

class _CoupleManageScreenState extends State<CoupleManageScreen> {
  bool isLoading = false;
  late String myCoupleCode;

  @override
  void initState() {
    super.initState();
    myCoupleCode = widget.initialCoupleCode;
  }

  Future<void> unlinkCouple() async {
    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("http://your-api-server.com/api/couples/unlink"),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("커플 연결이 해제되었습니다.")),
        );
        setState(() {
          myCoupleCode = "등록된 커플 코드 없음";
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("해제 실패: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("네트워크 오류 발생: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final logoHeight = size.height * 0.2;
    final topPadding = size.height * 0.01;

    return Scaffold(
      backgroundColor: Colors.transparent,
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: topPadding),

                // 로고
                SizedBox(
                  height: logoHeight,
                  child: Image.asset(
                    AppConstants.logoPath,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 20),

                const Center(
                  child: Text(
                    '커플 관리',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),

                const Spacer(),

                // 내 커플 코드 표시
                Center(
                  child: Column(
                    children: [
                      const Text(
                        "내 커플 코드",
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          myCoupleCode,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // 커플 해제 버튼
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RoundedButton(
                  text: "커플 해제",
                  onPressed: unlinkCouple,
                ),

                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
