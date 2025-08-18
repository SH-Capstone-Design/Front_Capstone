import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:share_plus/share_plus.dart'; // 공유 기능 패키지
import 'package:connectbeat/core/constants.dart';
import 'package:connectbeat/widgets/rounded_button.dart';
import 'package:connectbeat/widgets/bottom_bar.dart';

class InvitePartnerScreen extends ConsumerStatefulWidget {
  const InvitePartnerScreen({super.key});

  @override
  ConsumerState<InvitePartnerScreen> createState() => _InvitePartnerScreenState();
}

class _InvitePartnerScreenState extends ConsumerState<InvitePartnerScreen> {
  int _currentIndex = 0; // BottomBar 인덱스 (필요 시 조정)
  bool _isLoading = false; // 로딩 상태 관리
  final TextEditingController _inviteCodeController = TextEditingController();

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/history');
        break;
      case 1:
        Navigator.pushNamed(context, '/character');
        break;
      case 2:
        Navigator.pushNamed(context, '/');
        break;
      case 3:
        Navigator.pushNamed(context, '/setting');
        break;
    }
  }

  Future<void> _invitePartner() async {
    setState(() {
      _isLoading = true;
    });

    // try {
    //   // TODO: 실제 초대 링크 생성 로직 (예: 서버 API 호출)
    //   const inviteLink = 'https://connectbeat.app/invite/12345';
    //   await Share.share(
    //     'ConnectBeat에서 함께 채팅하세요! 초대 링크: $inviteLink',
    //     subject: 'ConnectBeat 초대',
    //   );
    //   // 초대 성공 후 /topic-select로 이동
    //   if (mounted) {
    //     Navigator.pushNamed(context, '/topic-select');
    //   }
    // } catch (e) {
    //   if (mounted) {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(content: Text('초대 실패: $e')),
    //     );
    //   }
    // } finally {
    //   if (mounted) {
    //     setState(() {
    //       _isLoading = false;
    //     });
    //   }
    // }
  }

  @override
  void dispose() {
    _inviteCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8FC), // 연한 핑크
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: size.width * 0.06),
          child: Column(
            children: [
              SizedBox(height: size.height * 0.06),
              // 앱 로고
              Center(
                child: Image.asset(
                  AppConstants.logoPath,
                  height: size.height * 0.05, // 반응형 높이
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.error,
                    size: 32,
                    color: Colors.red,
                  ),
                ),
              ),
              SizedBox(height: size.height * 0.03),
              // 안내 텍스트
              const Text(
                '파트너를 초대하여 함께 채팅을 시작하세요!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: size.height * 0.03),
              // 초대 코드 입력 필드
              TextField(
                controller: _inviteCodeController,
                decoration: InputDecoration(
                  labelText: '초대 코드 입력 (선택)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const Spacer(flex: 2),
              // 초대 버튼
              _isLoading
                  ? const CircularProgressIndicator()
                  : RoundedButton(
                text: '상대방 초대',
                onPressed: _invitePartner,      // 상대 수락 받으면 topic_select으로
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}