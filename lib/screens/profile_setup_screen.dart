import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:connectbeat/core/constants.dart';
import '../widgets/rounded_button.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String nickname;
  final String? profileImageUrl;

  const ProfileSetupScreen({
    super.key,
    required this.nickname,
    this.profileImageUrl,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  late TextEditingController _nicknameController;
  File? _pickedImage;
  String? _latestProfileUrl;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: widget.nickname);
    _fetchLatestProfile();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  // 최신 카카오 프로필 가져오기
  Future<void> _fetchLatestProfile() async {
    try {
      final user = await UserApi.instance.me();
      setState(() {
        _latestProfileUrl = user.kakaoAccount?.profile?.profileImageUrl;
      });
    } catch (e) {
      print('최신 프로필 URL 가져오기 실패: $e');
      setState(() {
        _latestProfileUrl = widget.profileImageUrl;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
    }
  }

  void _onContinuePressed() {
    final updatedNickname = _nicknameController.text.trim();
    if (updatedNickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('닉네임을 입력해주세요.')),
      );
      return;
    }

    Navigator.pushNamed(context, '/couple-code');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final logoHeight = size.height * 0.2;
    final topPadding = size.height * 0.01;

    return Scaffold(
      body: Stack(
        children: [
          // 배경 이미지
          SizedBox.expand(
            child: Image.asset(
              AppConstants.backgroundPath,
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.06),
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

                  const SizedBox(height: 16),

                  // 프로필 이미지
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white,
                        backgroundImage: _pickedImage != null
                            ? FileImage(_pickedImage!)
                            : (_latestProfileUrl != null
                            ? NetworkImage(_latestProfileUrl!) as ImageProvider
                            : null),
                        child: (_pickedImage == null && _latestProfileUrl == null)
                            ? const Icon(Icons.person, size: 60, color: Colors.grey)
                            : null,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Center(
                    child: Text('프로필 설정', style: TextStyle(fontSize: 14)),
                  ),

                  const SizedBox(height: 8),

                  // 닉네임 입력 필드
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextFormField(
                      controller: _nicknameController,
                      decoration: const InputDecoration(
                        hintText: '닉네임 설정',
                        border: UnderlineInputBorder(),
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  RoundedButton(
                    text: '커플 연결하기',
                    onPressed: _onContinuePressed,
                  ),

                  const Spacer(flex: 1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
