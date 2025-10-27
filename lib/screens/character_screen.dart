import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectbeat/core/constants.dart';
import 'package:connectbeat/widgets/rounded_button.dart';
import 'package:connectbeat/screens/preview_screen.dart';
import 'package:connectbeat/screens/backgroundpreview_screen.dart';

class CharacterScreen extends StatefulWidget {
  const CharacterScreen({super.key});

  @override
  State<CharacterScreen> createState() => _CharacterScreenState();
}

class _CharacterScreenState extends State<CharacterScreen> {
  String selectedCategory = '옷';
  final List<String> categories = ['옷', '배경'];

  // 👋 캐릭터 애니메이션
  Timer? _handTimer;
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

  // 선택 상태
  String? selectedItemName;
  String? selectedItemImage;

  // 카테고리별 아이템
  final Map<String, List<Map<String, dynamic>>> categoryItems = {
    '옷': [
      {'name': '흰 잠옷', 'image': 'assets/images/clothes/cloth_1.png', 'price': 30},
      {'name': '보라 잠옷', 'image': 'assets/images/clothes/cloth_2.png', 'price': 30},
      {'name': '파스텔 잠옷', 'image': 'assets/images/clothes/cloth_3.png', 'price': 45},
      {'name': '짱구 잠옷', 'image': 'assets/images/clothes/cloth_4.png', 'price': 100},
      {'name': '노란 잠옷', 'image': 'assets/images/clothes/cloth_5.png', 'price': 30},
      {'name': '빨간 자켓', 'image': 'assets/images/clothes/cloth_6.png', 'price': 50},
      {'name': '검정 자켓', 'image': 'assets/images/clothes/cloth_7.png', 'price': 50},
      {'name': '초록파랑 잠옷', 'image': 'assets/images/clothes/cloth_8.png', 'price': 45},
      {'name': '파란 자켓', 'image': 'assets/images/clothes/cloth_9.png', 'price': 60},
      {'name': '산타 옷', 'image': 'assets/images/clothes/cloth_10.png', 'price': 1000},
      {'name': '루돌프 옷', 'image': 'assets/images/clothes/cloth_11.png', 'price': 1000},
      {'name': '노란 우비', 'image': 'assets/images/clothes/cloth_12.png', 'price': 250},
      {'name': '연두 우비', 'image': 'assets/images/clothes/cloth_13.png', 'price': 250},
      {'name': '보라 우비', 'image': 'assets/images/clothes/cloth_14.png', 'price': 250},
      {'name': '빨강 우비', 'image': 'assets/images/clothes/cloth_15.png', 'price': 250},
    ],
    '배경': [
      {'name': '배경 1', 'image': 'assets/images/backgrounds/bg_1.png', 'price': 300},
      {'name': '배경 2', 'image': 'assets/images/backgrounds/bg_2.png', 'price': 300},
      {'name': '배경 3', 'image': 'assets/images/backgrounds/bg_3.png', 'price': 300},
      {'name': '배경 4', 'image': 'assets/images/backgrounds/bg_4.png', 'price': 300},
      {'name': '배경 5', 'image': 'assets/images/backgrounds/bg_5.png', 'price': 300},
      {'name': '배경 6', 'image': 'assets/images/backgrounds/bg_6.png', 'price': 300},
    ],
  };

  @override
  void initState() {
    super.initState();
    _handIndex = 0;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // 캐릭터 애니메이션 이미지 미리 로딩
      for (var img in _handImages) {
        await precacheImage(AssetImage(img), context);
      }

      // 아이템 이미지 미리 로딩
      for (var items in categoryItems.values) {
        for (var item in items) {
          await precacheImage(AssetImage(item['image']), context);
        }
      }

      // 손 흔드는 애니메이션 시작
      _handTimer = Timer.periodic(const Duration(milliseconds: 450), (_) {
        if (!mounted) return;
        setState(() {
          _handIndex = (_handIndex + 1) % _handImages.length;
        });
      });
    });
  }

  @override
  void dispose() {
    _handTimer?.cancel(); // nullable로 안전하게
    super.dispose();
  }

  // 상품 선택/미리보기/구매 다이얼로그
  Future<void> _showItemDialog(String itemName, String imagePath) async {
    final items = categoryItems[selectedCategory]!;
    final selectedIndex = items.indexWhere((item) => item['name'] == itemName);

    bool? purchaseConfirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Container(
          padding: const EdgeInsets.all(20),
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('상품 선택', style: TextStyle(fontSize: 22, fontFamily: 'GowunBatang', fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text('$itemName을(를) 선택했습니다.', textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: RoundedButton(text: '취소', onPressed: () => Navigator.pop(context, false)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RoundedButton(
                      text: '미리보기',
                      onPressed: () async {
                        Navigator.pop(context);
                        if (selectedCategory == '옷') {
                          // 캐릭터 미리보기
                          String folder = 'assets/images/characters/ch_${selectedIndex + 1}';
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => PreviewScreen(itemName: itemName, characterFolder: folder)),
                          );
                        } else if (selectedCategory == '배경') {
                          // 배경 미리보기
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BackgroundPreviewScreen(
                                backgroundName: itemName,
                                backgroundImagePath: imagePath,
                              ),
                            ),
                          );
                        }
                        // 미리보기 종료 후 다이얼로그 재오픈
                        _showItemDialog(itemName, imagePath);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RoundedButton(text: '구매', onPressed: () => Navigator.pop(context, true)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    // 구매 완료 처리
    if (purchaseConfirmed == true) {
      setState(() {
        selectedItemName = itemName;
        selectedItemImage = imagePath;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$itemName 구매 완료!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = categoryItems[selectedCategory]!;

    return Stack(
      children: [
        // 배경
        SizedBox.expand(child: Image.asset(AppConstants.backgroundPath, fit: BoxFit.cover)),
        SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              // 코인 표시
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Image.asset('assets/images/ConnectBeat_coin.png', width: 30, height: 30),
                    const SizedBox(width: 8),
                    const Text('10 개', style: TextStyle(fontFamily: 'GowunBatang', fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('캐릭터 꾸미기', style: TextStyle(fontFamily: 'GowunBatang', fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              // 캐릭터 애니메이션
              Expanded(
                flex: 5,
                child: Center(
                  child: Stack(
                    children: _handImages.asMap().entries.map((entry) {
                      int idx = entry.key;
                      String img = entry.value;
                      return Opacity(
                        opacity: idx == _handIndex ? 1.0 : 0.0,
                        child: Image.asset(img, fit: BoxFit.contain),
                      );
                    }).toList(),
                  ),
                ),
              ),
              // 카테고리 버튼
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: categories.map((category) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: RoundedButton(
                          text: category,
                          onPressed: () => setState(() => selectedCategory = category),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              // 아이템 그리드
              Expanded(
                flex: 4,
                child: Container(
                  color: Colors.white.withOpacity(0.2),
                  padding: const EdgeInsets.all(8),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return GestureDetector(
                        onTap: () => _showItemDialog(item['name'], item['image']),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white.withOpacity(0.2),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(2, 2))],
                            border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
                          ),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(item['image'], fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                              ),
                              Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.black.withOpacity(0.15))),
                              Positioned(
                                bottom: 6,
                                left: 6,
                                right: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(8)),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset('assets/images/ConnectBeat_coin.png', width: 16, height: 16),
                                      const SizedBox(width: 4),
                                      Text('${item['price']} 코인', style: const TextStyle(fontFamily: 'GowunBatang', color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
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
