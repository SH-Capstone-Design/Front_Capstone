// lib/screens/my_profile_setting_screen.dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/rounded_button.dart';
import '../core/constants.dart';

/// ------------------------
/// MyProfileSettingScreen
/// ------------------------
class MyProfileSettingScreen extends ConsumerStatefulWidget {
  const MyProfileSettingScreen({super.key});

  @override
  ConsumerState<MyProfileSettingScreen> createState() =>
      _MyProfileSettingScreenState();
}

class _MyProfileSettingScreenState
    extends ConsumerState<MyProfileSettingScreen> with TickerProviderStateMixin {
  late TextEditingController _nicknameController;
  File? _pickedImage;
  String? _latestProfileUrl;
  bool _isUploading = false;

  final List<_FloatingIcon> _icons = [];
  late AnimationController _avatarScaleController;
  late Animation<double> _avatarScaleAnimation;

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProvider).value;
    _nicknameController = TextEditingController(text: user?['nickname'] ?? '');
    _latestProfileUrl = user?['profileImage'];

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
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _avatarScaleController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ref.read(userProvider.notifier).pickImageFromGallery();
    if (picked == null) return;

    final file = File(picked.path);
    final bytes = await file.readAsBytes();

    final Uint8List? cropped = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CropPage(bytes: bytes),
      ),
    );

    if (cropped != null) {
      final saved = await _saveBytesToTempFile(cropped);
      setState(() => _pickedImage = saved);
    } else {
      setState(() => _pickedImage = file);
    }

    _avatarScaleController.forward().then((_) => _avatarScaleController.reverse());
  }

  Future<File> _saveBytesToTempFile(Uint8List bytes) async {
    final temp = await getTemporaryDirectory();
    final file = File('${temp.path}/crop_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<void> _onSavePressed() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('닉네임을 입력해주세요.')));
      return;
    }

    setState(() => _isUploading = true);

    try {
      if (_pickedImage != null) {
        final url = await ref.read(userProvider.notifier).uploadProfileImage(_pickedImage!);
        _latestProfileUrl = url;
        _pickedImage = null;
      }

      await ref.read(userProvider.notifier).updateNickname(nickname);

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("프로필이 저장되었습니다.")));
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("업데이트 실패: $e")));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    ImageProvider? avatar = _pickedImage != null
        ? FileImage(_pickedImage!)
        : (_latestProfileUrl != null && _latestProfileUrl!.isNotEmpty
            ? NetworkImage(_latestProfileUrl!)
            : null);

    return Scaffold(
      extendBodyBehindAppBar: true,
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
          // 배경 이미지
          Positioned.fill(
            child: Image.asset(
              AppConstants.backgroundPath,
              fit: BoxFit.cover,
            ),
          ),
          // 떠다니는 아이콘
          ..._icons.map((icon) {
            return Positioned(
              left: icon.dx * size.width,
              top: icon.dy * size.height +
                  sin(DateTime.now().millisecondsSinceEpoch / 500 + icon.dx * 10) * 10,
              child: Icon(icon.icon, size: icon.size, color: icon.color),
            );
          }).toList(),
          // 메인 UI
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: size.width * 0.06),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 100),
                          Center(
                            child: GestureDetector(
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
                                  fontFamily: 'GowunBatang', fontSize: 16),
                              decoration: const InputDecoration(
                                hintText: '닉네임 설정',
                                border: UnderlineInputBorder(),
                              ),
                            ),
                          ),
                          const Spacer(), // 버튼을 항상 하단으로
                          RoundedButton(
                            text: '저장하기',
                            onPressed: _isUploading ? null : _onSavePressed,
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// ------------------------
/// CropPage
/// ------------------------
class CropPage extends StatelessWidget {
  final Uint8List bytes;
  final CropController cropController;

  CropPage({super.key, required this.bytes})
      : cropController = CropController();

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
        aspectRatio: 1,
        onCropped: (cropped) {
          Navigator.pop(context, cropped);
        },
      ),
    );
  }
}

/// ------------------------
/// Floating Icon
/// ------------------------
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
