import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import '../core/constants.dart';
import '../providers/user_provider.dart';
import '../widgets/rounded_button.dart';

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

  Future<void> _fetchLatestProfile() async {
    try {
      final hasKakaoToken = await AuthApi.instance.hasToken();
      if (hasKakaoToken) {
        final user = await UserApi.instance.me();
        setState(() {
          _latestProfileUrl = user.kakaoAccount?.profile?.profileImageUrl;
        });
        return;
      }
    } catch (_) {}

    setState(() {
      _latestProfileUrl = widget.profileImageUrl;
    });
  }

  Future<void> _pickImage() async {
    final file = await ref.read(userProvider.notifier).pickImageFromGallery();
    if (file != null) {
      setState(() {
        _pickedImage = file;
      });
    }
  }

  Future<void> _onContinuePressed() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('닉네임을 입력해주세요.')));
      return;
    }

    String? imageUrl;
    if (_pickedImage != null) {
      imageUrl = _pickedImage!.path; // 실제 서버 업로드 후 URL로 교체 필요
    } else if (_latestProfileUrl != null && _latestProfileUrl!.isNotEmpty) {
      imageUrl = _latestProfileUrl;
    }

    try {
      await ref.read(userProvider.notifier).updateUser(
        nickname: nickname,
        profileImage: imageUrl,
      );
      Navigator.pushNamed(context, '/couple-code');
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('업데이트 실패: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final logoHeight = size.height * 0.2;
    final topPadding = size.height * 0.01;

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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: topPadding),
                    SizedBox(
                      height: logoHeight,
                      child: Image.asset(
                        AppConstants.logoPath,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: avatar,
                          child: avatar == null
                              ? const Icon(Icons.person,
                              size: 60, color: Colors.grey)
                              : null,
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
                      onPressed: _onContinuePressed,
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
