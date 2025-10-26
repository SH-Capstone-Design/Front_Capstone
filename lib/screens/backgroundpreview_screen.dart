import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectbeat/widgets/rounded_button.dart';

class BackgroundPreviewScreen extends StatefulWidget {
  final String backgroundName;
  final String backgroundImagePath;

  const BackgroundPreviewScreen({
    super.key,
    required this.backgroundName,
    required this.backgroundImagePath,
  });

  @override
  State<BackgroundPreviewScreen> createState() => _BackgroundPreviewScreenState();
}

class _BackgroundPreviewScreenState extends State<BackgroundPreviewScreen> {
  late Timer _handTimer;
  int _handIndex = 0;

  final List<String> _handFrames = List.generate(
    7,
        (index) => 'assets/images/characters/ch_0/frame_${index + 1}.png',
  );

  @override
  void initState() {
    super.initState();

    // 캐릭터 프레임 미리 로딩
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      for (var frame in _handFrames) {
        await precacheImage(AssetImage(frame), context);
      }

      _handTimer = Timer.periodic(const Duration(milliseconds: 450), (_) {
        if (!mounted) return;
        setState(() {
          _handIndex = (_handIndex + 1) % _handFrames.length;
        });
      });
    });
  }

  @override
  void dispose() {
    _handTimer.cancel();
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
            image: AssetImage(widget.backgroundImagePath),
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
                  '${widget.backgroundName} 미리보기',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),

              // 캐릭터 애니메이션 (하단)
              Positioned(
                bottom: 80, // 돌아가기 버튼 위쪽에 캐릭터 위치
                left: 0,
                right: 0,
                child: Stack(
                  alignment: Alignment.center,
                  children: _handFrames.asMap().entries.map((entry) {
                    int idx = entry.key;
                    String img = entry.value;
                    return Opacity(
                      opacity: idx == _handIndex ? 1.0 : 0.0,
                      child: Image.asset(
                        img,
                        fit: BoxFit.contain,
                        width: MediaQuery.of(context).size.width * 0.8,
                      ),
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
