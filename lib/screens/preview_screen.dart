import 'dart:async';
import 'package:connectbeat/core/constants.dart';
import 'package:flutter/material.dart';
import 'package:connectbeat/widgets/rounded_button.dart';

class PreviewScreen extends StatefulWidget {
  final String itemName;
  final String characterFolder; // ex: 'assets/images/characters/ch_2'

  const PreviewScreen({
    super.key,
    required this.itemName,
    required this.characterFolder,
  });

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  late List<String> _frames;
  int _frameIndex = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(milliseconds: 450), (timer) {
      if (!mounted) return;
      setState(() {
        _frameIndex = (_frameIndex + 1) % _frames.length;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadFrames();
  }

  void _loadFrames() {
    _frames = List.generate(
      7,
          (index) => '${widget.characterFolder}/frame_${index + 1}.png',
    );

    for (var frame in _frames) {
      precacheImage(AssetImage(frame), context);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppConstants.backgroundHomePath),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // 상단 텍스트
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Text(
                  '${widget.itemName} 미리보기',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),

              // 캐릭터 애니메이션
              Positioned(
                bottom: 20, // 버튼 바로 위에 위치
                left: 0,
                right: 0,
                child: Stack(
                  alignment: Alignment.center,
                  children: _frames.asMap().entries.map((entry) {
                    int idx = entry.key;
                    String img = entry.value;
                    return Opacity(
                      opacity: idx == _frameIndex ? 1.0 : 0.0,
                      child: Image.asset(img, fit: BoxFit.contain),
                    );
                  }).toList(),
                ),
              ),

              // 돌아가기 버튼
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: RoundedButton(
                  text: '돌아가기',
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
