import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectbeat/core/constants.dart';
import 'package:connectbeat/widgets/rounded_button.dart';

class CharacterScreen extends StatefulWidget {
  const CharacterScreen({super.key});

  @override
  State<CharacterScreen> createState() => _CharacterScreenState();
}

class _CharacterScreenState extends State<CharacterScreen> {
  String selectedCategory = '상의';
  final List<String> categories = ['상의', '하의'];

  // 👋 손 흔드는 애니메이션 관련
  late Timer _handTimer;
  int _handIndex = 0;
  final List<String> _handImages = [
    'assets/images/ConnectBeatCharacter.png',
    'assets/images/ConnectBeatCharacter3.png',
    'assets/images/ConnectBeatCharacter5.png',
    'assets/images/ConnectBeatCharacter4.png',
    'assets/images/ConnectBeatCharacter6.png',
    'assets/images/ConnectBeatCharacter3.png',
    'assets/images/ConnectBeatCharacter2.png',
  ];

  @override
  void initState() {
    super.initState();

    // 처음에 캐릭터 기본 이미지로 고정
    _handIndex = 0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (var imagePath in _handImages) {
        precacheImage(AssetImage(imagePath), context);
      }
    });

    _handTimer = Timer.periodic(const Duration(milliseconds: 450), (timer) {
      if (!mounted) return;
      setState(() {
        _handIndex = (_handIndex + 1) % _handImages.length;
      });
    });
  }

  @override
  void dispose() {
    _handTimer.cancel();
    super.dispose();
  }

  // ✅ 커스텀 다이얼로그
  Future<void> _showPurchaseDialog(String itemName) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 10,
        backgroundColor: Colors.white,
        child: Container(
          padding: const EdgeInsets.all(20),
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '구매 확인',
                style: TextStyle(
                  fontSize: 22,
                  fontFamily: 'GowunBatang',
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '$itemName을(를) 구매하시겠습니까?',
                style: const TextStyle(
                    fontSize: 18,
                    fontFamily: 'GowunBatang',
                    color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: RoundedButton(
                      text: '취소',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RoundedButton(
                      text: '확인',
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$itemName 구매 완료!')),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox.expand(
          child: Image.asset(
            AppConstants.backgroundPath,
            fit: BoxFit.cover,
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Image.asset(
                      'assets/images/ConnectBeat_coin.png',
                      width: 30,
                      height: 30,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '10 개',
                      style: TextStyle(
                        fontFamily: 'GowunBatang',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '캐릭터 꾸미기',
                style: TextStyle(
                  fontFamily: 'GowunBatang',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                flex: 5,
                child: Center(
                  child: Image.asset(
                    _handImages[_handIndex],
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: categories.map((category) {
                    final isSelected = selectedCategory == category;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: RoundedButton(
                          text: category,
                          onPressed: () {
                            setState(() {
                              selectedCategory = category;
                            });
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                flex: 4,
                child: Container(
                  color: Colors.white.withOpacity(0.2),
                  padding: const EdgeInsets.all(8),
                  child: GridView.builder(
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    itemCount: 6,
                    itemBuilder: (context, index) {
                      final itemName = '$selectedCategory ${index + 1}';
                      return GestureDetector(
                        onTap: () => _showPurchaseDialog(itemName),
                        child: Container(
                          color: Colors.pinkAccent.withOpacity(0.5),
                          child: Center(child: Text(itemName)),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
