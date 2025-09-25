import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import '../core/constants.dart';
import '../providers/user_provider.dart';
import '../widgets/rounded_button.dart';

class MyProfileSettingScreen extends ConsumerStatefulWidget {
  const MyProfileSettingScreen({super.key});

  @override
  ConsumerState<MyProfileSettingScreen> createState() =>
      _MyProfileSettingScreenState();
}

class _MyProfileSettingScreenState
    extends ConsumerState<MyProfileSettingScreen> {
  late TextEditingController _nicknameController;
  File? _pickedImage;
  String? _latestProfileUrl;

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProvider);
    _nicknameController =
        TextEditingController(text: user?['nickname'] ?? '');
    _latestProfileUrl = user?['profileImage'];

    _fetchLatestKakaoProfile();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _fetchLatestKakaoProfile() async {
    try {
      final hasKakaoToken = await AuthApi.instance.hasToken();
      if (hasKakaoToken) {
        final kakaoUser = await UserApi.instance.me();
        setState(() {
          _latestProfileUrl =
              kakaoUser.kakaoAccount?.profile?.profileImageUrl ??
                  _latestProfileUrl;
        });
      }
    } catch (_) {}
  }

  Future<void> _pickImage() async {
    final file = await ref.read(userProvider.notifier).pickImageFromGallery();
    if (file != null) {
      setState(() {
        _pickedImage = file;
      });
    }
  }

  Future<void> _onSavePressed() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('닉네임을 입력해주세요.')));
      return;
    }

    String? imageUrl;
    if (_pickedImage != null) {
      imageUrl = _pickedImage!.path;
    } else if (_latestProfileUrl != null && _latestProfileUrl!.isNotEmpty) {
      imageUrl = _latestProfileUrl;
    }

    try {
      await ref.read(userProvider.notifier).updateUser(
        nickname: nickname,
        profileImage: imageUrl,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('프로필이 저장되었습니다.')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('업데이트 실패: $e')));
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
      appBar: AppBar(
        title: const Text(
          '내 프로필 설정',
          style: TextStyle(fontFamily: 'GowunBatang', color: Colors.black),
        ),
        backgroundColor: Colors.transparent, // 투명
        foregroundColor: Colors.black, // 뒤로가기 버튼 색상
        elevation: 0, // 그림자 제거
      ),
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
                    const SizedBox(height: 20),
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
                          fontSize: 14,
                          fontFamily: 'GowunBatang',
                          fontWeight: FontWeight.bold,
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
                          fontSize: 16,
                        ),
                        decoration: const InputDecoration(
                          hintText: '닉네임 설정',
                          hintStyle: TextStyle(
                            fontFamily: 'GowunBatang',
                          ),
                          border: UnderlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    RoundedButton(
                      text: '저장하기',
                      onPressed: _onSavePressed,
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
