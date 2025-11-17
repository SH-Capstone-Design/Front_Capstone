import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import '../core/constants.dart';
import '../providers/user_provider.dart';
import '../widgets/rounded_button.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  final String nickname;
  final String? profileImageUrl;

  const ProfileSetupScreen({super.key, required this.nickname, this.profileImageUrl});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> with TickerProviderStateMixin {
  late TextEditingController _nicknameController;
  File? _pickedImage;
  String? _latestProfileUrl;
  bool _isUploading = false;

  late AnimationController _avatarScaleController;
  late Animation<double> _avatarScaleAnimation;

  final List<_FloatingIcon> _icons = [];

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: widget.nickname);

    _avatarScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _avatarScaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _avatarScaleController, curve: Curves.easeInOut),
    );

    for (int i = 0; i < 10; i++) {
      _icons.add(_FloatingIcon(
        dx: Random().nextDouble(),
        dy: Random().nextDouble(),
        size: Random().nextDouble() * 20 + 10,
        icon: i % 2 == 0 ? Icons.favorite : Icons.star,
        color: i % 2 == 0
            ? Colors.pinkAccent.withOpacity(0.7)
            : Colors.yellow.shade300.withOpacity(0.7),
      ));
    }

    _fetchLatestProfile();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _avatarScaleController.dispose();
    super.dispose();
  }

  Future<void> _fetchLatestProfile() async {
    try {
      final initialProfile = widget.profileImageUrl;
      if (initialProfile != null) {
        setState(() => _isUploading = true);
        final s3Url = await ref.read(userProvider.notifier).uploadProfileImageFromUrl(initialProfile);
        setState(() {
          _latestProfileUrl = s3Url;
          _isUploading = false;
        });
      }
    } catch (_) {
      setState(() => _isUploading = false);
    }
  }

  // -----------------------------
  //      이미지 선택 + 자르기
  // -----------------------------
  Future<void> _pickImage() async {
    final file = await ref.read(userProvider.notifier).pickImageFromGallery();
    if (file == null) return;

    // 윈도우 / 맥OS / 리눅스 / 웹에서는 크롭 건너뛰기
    if (!Platform.isAndroid && !Platform.isIOS) {
      setState(() => _pickedImage = File(file.path));
      return;
    }

    try {
      final cropped = await ImageCropper().cropImage(
        sourcePath: file.path,
        aspectRatioPresets: [
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio4x3,
          CropAspectRatioPreset.original,
        ],
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: "사진 자르기",
            toolbarColor: Colors.pinkAccent,
            toolbarWidgetColor: Colors.white,
          ),
          IOSUiSettings(title: "사진 자르기"),
        ],
      );

      if (cropped != null) {
        setState(() => _pickedImage = File(cropped.path));
        _avatarScaleController.forward().then((_) => _avatarScaleController.reverse());
      }
    } catch (e) {
      // Desktop에서는 image_cropper 호출하면 여기로 빠짐
      print("Crop not supported: $e");
      setState(() => _pickedImage = File(file.path));
    }
  }


  Future<void> _onContinuePressed() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('닉네임을 입력해주세요.')));
      return;
    }

    setState(() => _isUploading = true);

    try {
      String? imageUrl;
      if (_pickedImage != null) {
        imageUrl = await ref.read(userProvider.notifier).uploadProfileImage(_pickedImage!);
        setState(() {
          _latestProfileUrl = imageUrl;
          _pickedImage = null;
        });
      }

      await ref.read(userProvider.notifier).updateNickname(nickname);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('프로필이 저장되었습니다.')));
        Navigator.pushNamed(context, '/couple-code');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('업데이트 실패: $e')));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    ImageProvider? avatar = _pickedImage != null
        ? FileImage(_pickedImage!)
        : (_latestProfileUrl != null ? NetworkImage(_latestProfileUrl!) : null);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(AppConstants.backgroundPath),
                fit: BoxFit.cover,
              ),
            ),
          ),

          ..._icons.map((icon) {
            return Positioned(
              left: icon.dx * size.width,
              top: icon.dy * size.height +
                  sin(DateTime.now().millisecondsSinceEpoch / 500 + icon.dx * 10) * 10,
              child: Icon(icon.icon, size: icon.size, color: icon.color),
            );
          }).toList(),

          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.06),
                child: Column(
                  children: [
                    SizedBox(height: size.height * 0.05),
                    GestureDetector(
                      onTap: _pickImage,
                      child: ScaleTransition(
                        scale: _avatarScaleAnimation,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: avatar,
                              child: avatar == null
                                  ? const Icon(Icons.person, size: 60, color: Colors.grey)
                                  : null,
                            ),
                            if (_isUploading) const CircularProgressIndicator(),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: size.height * 0.03),
                    Text(
                      '프로필 설정 💌',
                      style: TextStyle(
                        fontFamily: 'GowunBatang',
                        fontSize: size.height * 0.022,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: size.height * 0.01),
                    TextFormField(
                      controller: _nicknameController,
                      decoration: const InputDecoration(hintText: '닉네임'),
                    ),
                    SizedBox(height: size.height * 0.05),
                    RoundedButton(
                      text: '커플 연결하기',
                      onPressed: _isUploading ? null : _onContinuePressed,
                    ),
                    SizedBox(height: size.height * 0.03),
                    const Text("💞 서로의 마음이 닿을 때, 앱을 시작할 수 있어요 💞"),
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

class _FloatingIcon {
  final double dx, dy, size;
  final IconData icon;
  final Color color;

  _FloatingIcon({
    required this.dx,
    required this.dy,
    required this.size,
    required this.icon,
    required this.color,
  });
}
