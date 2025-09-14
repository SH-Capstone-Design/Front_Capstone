import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectbeat/core/constants.dart';
import '../widgets/rounded_button.dart';
import '../services/auth_service.dart';

class MyProfileSettingScreen extends StatefulWidget {
  const MyProfileSettingScreen({super.key});

  @override
  State<MyProfileSettingScreen> createState() => _MyProfileSettingScreenState();
}

class _MyProfileSettingScreenState extends State<MyProfileSettingScreen> {
  final _nicknameController = TextEditingController();
  bool _loading = false;

  File? _selectedImage;
  String? _profileImageUrl; // 서버에서 가져온 기존 이미지
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  // 1️⃣ 기존 사용자 정보 불러오기
  Future<void> _loadUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = await AuthService.getToken();
      if (token == null) throw Exception("JWT가 존재하지 않습니다.");

      final baseUrl = dotenv.env['BASE_URL'] ?? "";
      final url = Uri.parse('$baseUrl/users/me');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _nicknameController.text = data['nickname'] ?? '';
          _profileImageUrl = data['profileImage'];
        });
      } else {
        debugPrint("사용자 정보 조회 실패: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("사용자 정보 조회 중 오류: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("사용자 정보 조회 중 오류: $e")),
      );
    }
  }

  // 2️⃣ 이미지 선택
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // 3️⃣ 서버로 이미지 업로드 (POST /users/me/profile-image)
  Future<String?> _uploadProfileImage(File file) async {
    final prefs = await SharedPreferences.getInstance();
    final token = await AuthService.getToken();
    final baseUrl = dotenv.env['BASE_URL'] ?? "";
    final url = Uri.parse('$baseUrl/users/me/profile-image');

    final request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final data = jsonDecode(respStr);
      return data['profileImageUrl']; // 서버가 반환하는 URL
    } else {
      debugPrint("이미지 업로드 실패: ${response.statusCode}");
      return null;
    }
  }

  // 4️⃣ 프로필 수정 (PUT /users/me)
  Future<bool> _updateProfile({required String nickname, required String profileImageUrl}) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception("JWT가 존재하지 않습니다.");

    final baseUrl = dotenv.env['BASE_URL'] ?? "";
    final url = Uri.parse('$baseUrl/users/me');

    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'nickname': nickname,
        'profileImage': profileImageUrl,
      }),
    );

    return response.statusCode == 200;
  }

  // 5️⃣ 저장 버튼
  Future<void> _onSave() async {
    setState(() => _loading = true);

    try {
      String profileImageUrl = _profileImageUrl ?? "";

      if (_selectedImage != null) {
        final uploadedUrl = await _uploadProfileImage(_selectedImage!);
        if (uploadedUrl == null) throw Exception("이미지 업로드 실패");
        profileImageUrl = uploadedUrl;
      }

      final success = await _updateProfile(
        nickname: _nicknameController.text.trim(),
        profileImageUrl: profileImageUrl,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ 프로필이 수정되었습니다.")),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception("프로필 수정 실패");
      }
    } catch (e) {
      debugPrint(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ 오류 발생: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
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

                  SizedBox(height: size.height * 0.02),

                  const Center(
                    child: Text(
                      '내 프로필 수정',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 닉네임 입력
                  TextField(
                    controller: _nicknameController,
                    decoration: const InputDecoration(
                      labelText: "닉네임",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 이미지 선택 / 기존 프로필 표시
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: ClipOval(
                        child: SizedBox(
                          width: 120,
                          height: 120,
                          child: _selectedImage != null
                              ? Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                          )
                              : (_profileImageUrl != null && _profileImageUrl!.isNotEmpty
                              ? Image.network(
                            _profileImageUrl!,
                            fit: BoxFit.cover,
                          )
                              : Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.camera_alt, size: 50),
                          )),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : RoundedButton(
                    text: "저장하기",
                    onPressed: _onSave,
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
