// lib/screens/myprofile_setting_screen.dart
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:mime/mime.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../core/constants.dart';
import '../providers/user_provider.dart';
import '../widgets/rounded_button.dart';
import '../services/auth_service.dart';

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
    final userState = ref.read(userProvider);
    final user = userState.value;
    _nicknameController = TextEditingController(text: user?['nickname'] ?? '');
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
              kakaoUser.kakaoAccount?.profile?.profileImageUrl ?? _latestProfileUrl;
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

  /// 🔹 S3 업로드
  Future<String?> _uploadImage(File imageFile) async {
    final token = await AuthService.getToken();
    print('JWT Token: $token');
    if (token == null) return null;

    final uri = Uri.parse('${dotenv.env['BASE_URL']}/users/me/profile-image');
    print('POST URL: ${dotenv.env['BASE_URL']}/users/me/profile-image');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';

    final mimeType = lookupMimeType(imageFile.path)?.split('/') ?? ['image', 'jpeg'];

    request.files.add(await http.MultipartFile.fromPath(
      'image',
      imageFile.path,
      contentType: MediaType(mimeType[0], mimeType[1]),
    ));

    final response = await request.send();
    final respStr = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(respStr);
      return data['profileImageUrl'];
    } else {
      throw Exception('업로드 실패: ${response.statusCode} $respStr');
    }
  }

  Future<void> _onSavePressed() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('닉네임을 입력해주세요.')));
      return;
    }

    try {
      String? imageUrl;
      if (_pickedImage != null) {
        imageUrl = await _uploadImage(_pickedImage!);
      } else if (_latestProfileUrl != null && _latestProfileUrl!.isNotEmpty) {
        imageUrl = _latestProfileUrl;
      }

      await ref.read(userProvider.notifier).updateUser(
        nickname: nickname,
        profileImage: imageUrl,
      );

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('프로필이 저장되었습니다.')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('업데이트 실패: $e')));
      print(e);
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
    if (userState.hasError) {
      return Scaffold(
        body: Center(child: Text('사용자 정보 불러오기 실패')),
      );
    }

    final user = userState.value;
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
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
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