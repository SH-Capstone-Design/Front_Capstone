// lib/screens/my_profile_setting_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import '../providers/user_provider.dart';
import '../widgets/rounded_button.dart';
import '../core/constants.dart';

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
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProvider).value;
    _nicknameController = TextEditingController(text: user?['nickname'] ?? '');
    _latestProfileUrl = user?['profileImage'];
  }

  /// ✅ 이미지 자르기 기능 추가
  Future<File?> _cropImage(File imageFile) async {
    // ⛔ Windows, macOS, Linux, Web에서는 크롭하지 않음
    if (!Platform.isAndroid && !Platform.isIOS) {
      return imageFile; // 원본 그대로 사용
    }

    try {
      final cropped = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        aspectRatioPresets: [
          CropAspectRatioPreset.square, // 정사각형 (프로필용)
        ],
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: '이미지 자르기',
            toolbarColor: Colors.pinkAccent,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: '이미지 자르기',
            aspectRatioLockEnabled: true,
          ),
        ],
      );

      return cropped != null ? File(cropped.path) : null;
    } catch (e) {
      // 혹시 예외 발생해도 앱은 정상 작동
      print("Image crop not supported on this platform: $e");
      return imageFile;
    }
  }

  /// 갤러리에서 이미지 선택
  Future<void> _pickImage() async {
    final file = await ref.read(userProvider.notifier).pickImageFromGallery();
    if (file != null) {
      final croppedFile = await _cropImage(file);
      if (croppedFile != null) {
        setState(() => _pickedImage = croppedFile);
      }
    }
  }

  /// 저장 버튼 눌렀을 때
  Future<void> _onSavePressed() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('닉네임을 입력해주세요.')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      // 1️⃣ 이미지 업로드
      if (_pickedImage != null) {
        final imageUrl = await ref
            .read(userProvider.notifier)
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
        Navigator.pop(context, true);
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
      extendBodyBehindAppBar: true,
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
          SizedBox.expand(
            child: Image.asset(
              AppConstants.backgroundPath,
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.06),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 100),
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
                                ? const Icon(Icons.person,
                                size: 60, color: Colors.grey)
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
                    onPressed: _isUploading ? null : _onSavePressed,
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
