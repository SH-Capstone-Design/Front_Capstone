// lib/screens/profile_setup_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import '../core/constants.dart';
import '../providers/user_provider.dart';
import '../widgets/rounded_button.dart';
import '../services/S3_service.dart'; // S3 업로드 서비스 import

class ProfileSetupScreen extends ConsumerStatefulWidget {
  final String nickname;
  final String? profileImageUrl;

  const ProfileSetupScreen({
    super.key,
    required this.nickname,
    this.profileImageUrl,
  });

  @override
  ConsumerState<ProfileSetupScreen> createState() =>
      _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  late TextEditingController _nicknameController;
  File? _pickedImage;
  String? _latestProfileUrl;
  bool _isUploading = false;

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

  /// 카카오 프로필 또는 전달받은 프로필 이미지 불러오기 후 S3 업로드
  Future<void> _fetchLatestProfile() async {
    try {
      final hasKakaoToken = await AuthApi.instance.hasToken();
      String? initialProfile = widget.profileImageUrl;

      if (hasKakaoToken) {
        final user = await UserApi.instance.me();
        final kakaoProfile = user.kakaoAccount?.profile?.profileImageUrl;
        if (kakaoProfile != null && kakaoProfile.isNotEmpty) {
          initialProfile = kakaoProfile;
        }
      }

      if (initialProfile != null && initialProfile.isNotEmpty) {
        setState(() => _isUploading = true);
        final s3Url = await ref.read(userProvider.notifier)
            .uploadProfileImageFromUrl(initialProfile);
        setState(() {
          _latestProfileUrl = s3Url;
          _isUploading = false;
        });
      }
    } catch (e) {
      setState(() {
        _latestProfileUrl = widget.profileImageUrl;
        _isUploading = false;
      });
    }
  }

  /// 갤러리에서 이미지 선택
  Future<void> _pickImage() async {
    final file = await ref.read(userProvider.notifier).pickImageFromGallery();
    if (file != null) {
      setState(() {
        _pickedImage = file;
      });
    }
  }

  /// 저장 후 커플 코드 화면 이동
  Future<void> _onContinuePressed() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('닉네임을 입력해주세요.')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      String? imageUrl;

      // 1️⃣ 새로 선택한 이미지가 있으면 업로드
      if (_pickedImage != null) {
        imageUrl = await ref.read(userProvider.notifier)
            .uploadProfileImage(_pickedImage!);
        setState(() {
          _latestProfileUrl = imageUrl;
          _pickedImage = null;
        });
      }

      // 2️⃣ 닉네임 업데이트
      await ref.read(userProvider.notifier).updateNickname(nickname);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('프로필이 저장되었습니다.')),
        );
        Navigator.pushNamed(context, '/couple-code');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('업데이트 실패: $e')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    ImageProvider? avatar;
    if (_pickedImage != null) {
      avatar = FileImage(_pickedImage!);
    } else if (_latestProfileUrl != null && _latestProfileUrl!.isNotEmpty) {
      avatar = NetworkImage(_latestProfileUrl!);
    }

    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset(
              AppConstants.backgroundPath,
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.06),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: avatar,
                              child: avatar == null
                                  ? const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.grey,
                              )
                                  : null,
                            ),
                            if (_isUploading)
                              const CircularProgressIndicator(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        '프로필 설정',
                        style: TextStyle(
                          fontFamily: 'GowunBatang',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextFormField(
                        controller: _nicknameController,
                        style: const TextStyle(
                          fontFamily: 'GowunBatang',
                          fontSize: 14,
                          color: Colors.black,
                        ),
                        decoration: const InputDecoration(
                          hintText: '닉네임 설정',
                          hintStyle: TextStyle(
                            fontFamily: 'GowunBatang',
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          border: UnderlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    RoundedButton(
                      text: '커플 연결하기',
                      onPressed: _isUploading ? null : _onContinuePressed,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
