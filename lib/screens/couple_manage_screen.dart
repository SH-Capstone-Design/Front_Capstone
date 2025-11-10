import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:connectbeat/core/constants.dart';
import '../widgets/rounded_button.dart';
import '../services/auth_service.dart';
import '../services/couple_service.dart';

class CoupleManageScreen extends StatefulWidget {
  const CoupleManageScreen({super.key});

  @override
  State<CoupleManageScreen> createState() => _CoupleManageScreenState();
}

class _CoupleManageScreenState extends State<CoupleManageScreen> {
  Map<String, dynamic>? myInfo;
  Map<String, dynamic>? coupleInfo;
  bool loading = true;
  String linkedDate = '-';
  String anniversaryDate = '-';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => loading = true);
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception("로그인이 필요합니다.");

      final myProfile = await AuthService.getUserProfile();
      final coupleData = await CoupleService.fetchCoupleStatus();

      if (coupleData == null) throw Exception("커플 정보 조회 실패");

      final linkedAt = coupleData['linkedAt'] ?? '';
      final anniversary = coupleData['anniversaryDate'] ?? '';

      String linkedDateFormatted = '-';
      String anniversaryDateFormatted = '-';

      try {
        if (linkedAt.isNotEmpty) {
          linkedDateFormatted =
              DateFormat('yyyy.MM.dd').format(DateTime.parse(linkedAt));
        }
      } catch (_) {}

      try {
        if (anniversary.isNotEmpty) {
          anniversaryDateFormatted =
              DateFormat('yyyy.MM.dd').format(DateTime.parse(anniversary));
        }
      } catch (_) {}

      setState(() {
        myInfo = myProfile != null
            ? {
          'nickname': myProfile.nickname ?? '-',
          'profileImage': myProfile.profileImage,
        }
            : {'nickname': '-', 'profileImage': null};
        coupleInfo = coupleData;
        linkedDate = linkedDateFormatted;
        anniversaryDate = anniversaryDateFormatted;
        loading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("데이터 로드 실패: $e")),
        );
        setState(() => loading = false);
      }
    }
  }

  Future<void> _unlinkCouple() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return;

      final success = await CoupleService.unlinkCouple(token);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("커플이 해제되었습니다.")),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("커플 해제 실패")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("커플 해제 실패: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const infoFontSize = 18.0;

    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          '커플 관리',
          style: TextStyle(
            fontFamily: 'GowunBatang',
            fontSize: 22,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppConstants.backgroundPath),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    children: [
                      // 내 정보 & 연인 정보
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 나
                          Column(
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundImage: myInfo?['profileImage'] != null
                                    ? NetworkImage(myInfo!['profileImage'])
                                    : null,
                                child: myInfo?['profileImage'] == null
                                    ? const Icon(Icons.person, size: 40)
                                    : null,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                myInfo?['nickname'] ?? '-',
                                style: const TextStyle(
                                    fontFamily: 'GowunBatang',
                                    fontSize: 16,
                                    color: Colors.black),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text("❤️", style: TextStyle(fontSize: 24)),
                          ),
                          // 연인
                          Column(
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundImage:
                                coupleInfo?['partnerProfileImage'] != null
                                    ? NetworkImage(
                                    coupleInfo!['partnerProfileImage'])
                                    : null,
                                child: coupleInfo?['partnerProfileImage'] == null
                                    ? const Icon(Icons.person, size: 40)
                                    : null,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                coupleInfo?['partnerNickname'] ?? '-',
                                style: const TextStyle(
                                    fontFamily: 'GowunBatang',
                                    fontSize: 16,
                                    color: Colors.black),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // 연애 시작일
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cake, color: Color(0xFFEC9FFF)),
                          const SizedBox(width: 6),
                          Text(
                            "연애 시작일: $anniversaryDate",
                            style: const TextStyle(
                                fontFamily: 'GowunBatang',
                                fontSize: infoFontSize - 2,
                                color: Colors.black),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 앱 연결일
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.link, color: Color(0xFFEC9FFF)),
                          const SizedBox(width: 6),
                          Text(
                            "우리 앱과 만난지: $linkedDate",
                            style: const TextStyle(
                                fontFamily: 'GowunBatang',
                                fontSize: infoFontSize - 2,
                                color: Colors.black),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 커플 해제 버튼 고정
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: RoundedButton(
                  text: '커플 해제',
                  onPressed: _unlinkCouple,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
