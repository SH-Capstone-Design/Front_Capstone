// lib/screens/my_profile_setting_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_provider.dart';
import '../widgets/rounded_button.dart';
import '../core/constants.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';

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
    final user = ref.read(userProvider).value;
    _nicknameController = TextEditingController(text: user?['nickname'] ?? '');
    _latestProfileUrl = user?['profileImage'];
    _fetchLatestKakaoProfile();
  }

  Future<void> _fetchLatestKakaoProfile() async {
    try {
      if (await AuthApi.instance.hasToken()) {
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
      setState(() => _pickedImage = file);
    }
  }

  Future<void> _onSavePressed() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('닉네임을 입력해주세요.')),
      );
      return;
    }

    try {
      // 1️⃣ 이미지 업로드 (선택된 경우)
      if (_pickedImage != null) {
        final imageUrl =
        await ref.read(userProvider.notifier).uploadProfileImage(_pickedImage!);
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
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('업데이트 실패: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final userState = ref.watch(userProvider);

    if (userState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    ImageProvider? avatar;
    if (_pickedImage != null) {
      avatar = FileImage(_pickedImage!);
    } else if (_latestProfileUrl != null && _latestProfileUrl!.isNotEmpty) {
      avatar = NetworkImage(_latestProfileUrl!);
    }

    return Scaffold(
      extendBodyBehindAppBar: true, // AppBar 뒤로 배경 확장
      appBar: AppBar(
        title: const Text(
          '내 프로필 설정',
          style: TextStyle(fontFamily: 'GowunBatang', color: Colors.black),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // 배경 이미지
          SizedBox.expand(
            child: Image.asset(
              AppConstants.backgroundPath,
              fit: BoxFit.cover,
            ),
          ),
          // SafeArea + 화면 내용
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.06),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 100), // AppBar 아래 여백 확보
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
        ],
      ),
    );
  }
}
