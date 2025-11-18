import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/rounded_button.dart';
import '../core/constants.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  final String nickname;
  final String? profileImageUrl;

  const ProfileSetupScreen({
    super.key,
    required this.nickname,
    this.profileImageUrl,
  });

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen>
    with TickerProviderStateMixin {
  late TextEditingController _nicknameController;
  File? _pickedImage;
  String? _latestProfileUrl;
  bool _isUploading = false;

  final CropController _cropController = CropController();

  late AnimationController _avatarScaleController;
  late Animation<double> _avatarScaleAnimation;

  final List<_FloatingIcon> _icons = [];

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: widget.nickname);

    _avatarScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _avatarScaleAnimation = CurvedAnimation(
      parent: _avatarScaleController,
      curve: Curves.easeInOut,
    );

    final random = Random();
    for (int i = 0; i < 10; i++) {
      _icons.add(_FloatingIcon(
        dx: random.nextDouble(),
        dy: random.nextDouble(),
        size: random.nextDouble() * 18 + 12,
        icon: i.isEven ? Icons.favorite : Icons.star,
        color: i.isEven
            ? Colors.pinkAccent.withOpacity(0.7)
            : Colors.amber.withOpacity(0.75),
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
    if (widget.profileImageUrl == null) return;
    try {
      setState(() => _isUploading = true);

      final url = await ref
          .read(userProvider.notifier)
          .uploadProfileImageFromUrl(widget.profileImageUrl!);

      setState(() => _latestProfileUrl = url);
    } finally {
      setState(() => _isUploading = false);
    }
  }

  /// 이미지 선택 + Crop
  Future<void> _pickImage() async {
    final file = await ref.read(userProvider.notifier).pickImageFromGallery();
    if (file == null) return;

    final originalFile = File(file.path);
    final bytes = await originalFile.readAsBytes();

    final Uint8List? croppedBytes = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CropPage(bytes: bytes),
      ),
    );

    if (croppedBytes != null) {
      final saved = await _saveBytesToTempFile(croppedBytes);
      setState(() => _pickedImage = saved);
    } else {
      setState(() => _pickedImage = originalFile);
    }

    _avatarScaleController.forward().then((_) => _avatarScaleController.reverse());
  }

  Future<File> _saveBytesToTempFile(Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/crop_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<void> _onContinuePressed() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("닉네임을 입력해주세요.")));
      return;
    }

    setState(() => _isUploading = true);
    try {
      if (_pickedImage != null) {
        final url = await ref.read(userProvider.notifier).uploadProfileImage(_pickedImage!);
        _latestProfileUrl = url;
      }

      await ref.read(userProvider.notifier).updateNickname(nickname);

      if (mounted) Navigator.pushNamed(context, '/couple-code');
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
          Positioned.fill(
            child: Image.asset(
              AppConstants.backgroundPath,
              fit: BoxFit.cover,
            ),
          ),
          ..._icons.map((icon) {
            final animY = sin(DateTime.now().millisecondsSinceEpoch / 650 + icon.dx * 8) * 12;
            return Positioned(
              left: icon.dx * size.width,
              top: icon.dy * size.height + animY,
              child: Icon(icon.icon, size: icon.size, color: icon.color),
            );
          }),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.06),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: size.height * 0.06),
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
                                  ? const Icon(Icons.person, size: 64, color: Colors.grey)
                                  : null,
                            ),
                            if (_isUploading) const CircularProgressIndicator(),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: size.height * 0.03),
                    const Text(
                      '프로필 설정 💌',
                      style: TextStyle(
                        fontFamily: 'GowunBatang',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: size.height * 0.02),
                    TextFormField(
                      controller: _nicknameController,
                      decoration: const InputDecoration(
                        hintText: "닉네임",
                        border: UnderlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: size.height * 0.05),
                    RoundedButton(
                      text: "커플 연결하기",
                      onPressed: _isUploading ? null : _onContinuePressed,
                    ),
                    SizedBox(height: size.height * 0.05),
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

/// Crop 화면
class CropPage extends StatelessWidget {
  final Uint8List bytes;
  final CropController cropController = CropController();

  CropPage({super.key, required this.bytes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("이미지 자르기"),
        actions: [
          TextButton(
            onPressed: () => cropController.crop(),
            child: const Text("완료", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: Crop(
        controller: cropController,
        image: bytes,
        aspectRatio: null ,
        onCropped: (cropped) {
          Navigator.pop(context, cropped);
        },
      ),
    );
  }
}

class _FloatingIcon {
  final double dx, dy;
  final double size;
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
