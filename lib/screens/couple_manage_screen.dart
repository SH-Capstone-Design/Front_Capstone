import 'dart:convert';
import 'package:flutter/material.dart';
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

  /// ================================
  /// 🔥 커플 해제
  /// ================================
  Future<void> _unlinkCouple() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("커플 해제"),
        content: const Text("두 분의 정보는 30일간 보관됩니다.\n정말 커플 연결을 해제하시겠습니까?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("취소"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("해제"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final token = await AuthService.getToken();
      if (token == null) return;

      final success = await CoupleService.unlinkCouple(token);

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("커플 해제 실패")),
        );
        return;
      }

      // 🔥 서버 DB 동기화를 기다리기 위한 딜레이 (중요!)
      await Future.delayed(const Duration(milliseconds: 500));

      // 🔥 서버 상태 재확인
      final status = await CoupleService.fetchCoupleStatus();

      // 🔥 status가 NONE 또는 UNLINKED인지 확인
      if (status == null ||
          (status['status'] != 'NONE' && status['status'] != 'UNLINKED')) {
        print("⚠ 서버가 아직 상태 초기화 안됨 → 재확인 필요");
        await Future.delayed(const Duration(seconds: 1));
      }

      // 🔥 2차 확인
      final finalStatus = await CoupleService.fetchCoupleStatus();

      if (finalStatus == null ||
          (finalStatus['status'] != 'NONE' &&
              finalStatus['status'] != 'UNLINKED')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("서버 상태 초기화 지연 중입니다.")),
        );
        return;
      }

      // 🔥 여기 도착하면 확실히 unlink 성공
      await AuthService.deleteToken();
      await AuthService.deleteGoogleIdToken();

      if (mounted) {
        await showDialog(
          context: context,
          builder: (_) => const AlertDialog(
            title: Text("커플 해제 완료"),
            content: Text("커플 연결이 해제되었습니다."),
          ),
        );
      }

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 16),
                  child: Column(
                    children: [
                      /// ===============================
                      /// 내 정보 & 연인 정보
                      /// ===============================
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
                                  color: Colors.black,
                                ),
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
                                    ? NetworkImage(coupleInfo![
                                'partnerProfileImage'])
                                    : null,
                                child: coupleInfo?['partnerProfileImage'] ==
                                    null
                                    ? const Icon(Icons.person, size: 40)
                                    : null,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                coupleInfo?['partnerNickname'] ?? '-',
                                style: const TextStyle(
                                  fontFamily: 'GowunBatang',
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      /// 연애 시작일
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
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      /// 앱 연결일
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
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              /// ========================
              /// 🔥 커플 해제 버튼
              /// ========================
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
