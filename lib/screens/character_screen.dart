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

/// 🔹 자동 슬라이드 배너 위젯
class BannerSlider extends StatefulWidget {
  final List<String> imagePaths;
  const BannerSlider({super.key, required this.imagePaths});

  @override
  State<BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<BannerSlider> {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      _currentPage = (_currentPage + 1) % widget.imagePaths.length;
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return SizedBox(
      height: screenHeight * 0.23, // 화면 비율 기반 높이
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imagePaths.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              bool isActive = index == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: EdgeInsets.symmetric(
                  horizontal: isActive ? 8 : 12,
                  vertical: isActive ? 4 : 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isActive ? 0.3 : 0.15),
                      blurRadius: isActive ? 12 : 6,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    widget.imagePaths[index],
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              );
            },
          ),
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.imagePaths.length, (index) {
                bool isActive = index == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 10 : 8,
                  height: isActive ? 10 : 8,
                  decoration: BoxDecoration(
                    color: isActive ? Colors.black : Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

/// 🔹 캐릭터 상점 메인 화면
class _CharacterScreenState extends State<CharacterScreen> {
  String selectedCategory = '옷';
  final List<String> categories = ['옷', '배경'];

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

  String? selectedItemName;
  String? selectedItemImage;

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
      for (var img in _handImages) {
        await precacheImage(AssetImage(img), context);
      }
      _handTimer = Timer.periodic(const Duration(milliseconds: 450), (_) {
        if (!mounted) return;
        setState(() => _handIndex = (_handIndex + 1) % _handImages.length);
      });
    });
  }

  @override
  void dispose() {
    _handTimer?.cancel();
    super.dispose();
  }

  Future<void> _showItemDialog(String itemName, String imagePath) async {
    final items = categoryItems[selectedCategory]!;
    final selectedIndex = items.indexWhere((item) => item['name'] == itemName);

    bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('상품 선택', style: TextStyle(fontSize: 20, fontFamily: 'GowunBatang', fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text('$itemName을(를) 선택했습니다.'),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: RoundedButton(text: '취소', onPressed: () => Navigator.pop(context, false))),
                  const SizedBox(width: 6),
                  Expanded(
                    child: RoundedButton(
                      text: '미리보기',
                      onPressed: () async {
                        Navigator.pop(context);
                        if (selectedCategory == '옷') {
                          String folder = 'assets/images/characters/ch_${selectedIndex + 1}';
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => PreviewScreen(itemName: itemName, characterFolder: folder)),
                          );
                        } else {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => BackgroundPreviewScreen(backgroundName: itemName, backgroundImagePath: imagePath)),
                          );
                        }
                        _showItemDialog(itemName, imagePath);
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(child: RoundedButton(text: '구매', onPressed: () => Navigator.pop(context, true))),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      setState(() {
        selectedItemName = itemName;
        selectedItemImage = imagePath;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$itemName 구매 완료!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final items = categoryItems[selectedCategory]!;

    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(child: Image.asset(AppConstants.backgroundPath, fit: BoxFit.cover)),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screen.width * 0.04),
              child: Column(
                children: [
                  SizedBox(height: screen.height * 0.02),
                  Row(
                    children: [
                      Image.asset('assets/images/ConnectBeat_coin.png', width: screen.width * 0.08),
                      SizedBox(width: screen.width * 0.02),
                      Text('10코인',
                          style: TextStyle(
                            fontFamily: 'GowunBatang',
                            fontSize: screen.width * 0.045,
                            fontWeight: FontWeight.bold,
                          )),
                      const Spacer(),
                      Text('캐릭터 상점',
                          style: TextStyle(
                            fontFamily: 'GowunBatang',
                            fontSize: screen.width * 0.06,
                            fontWeight: FontWeight.bold,
                          )),
                      const Spacer(flex: 2),
                    ],
                  ),
                  SizedBox(height: screen.height * 0.02),

                  /// 🔹 배너
                  BannerSlider(
                    imagePaths: [
                      'assets/images/ConnectBeat_Baenur.png',
                      'assets/images/ConnectBeat_Baenur1.png',
                    ],
                  ),

                  SizedBox(height: screen.height * 0.025),

                  /// 🔹 캐릭터 애니메이션
                  Expanded(
                    flex: 6,
                    child: Center(
                      child: Stack(
                        children: _handImages.asMap().entries.map((entry) {
                          return Opacity(
                            opacity: entry.key == _handIndex ? 1.0 : 0.0,
                            child: Image.asset(
                              entry.value,
                              height: screen.height * 0.7,
                              fit: BoxFit.contain,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  /// 🔹 카테고리 버튼
                  Row(
                    children: categories.map((category) {
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: screen.width * 0.01),
                          child: RoundedButton(
                            text: category,
                            onPressed: () => setState(() => selectedCategory = category),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  SizedBox(height: screen.height * 0.015),

                  /// 🔹 아이템 그리드
                  Expanded(
                    flex: 4,
                    child: Container(
                      color: Colors.white.withOpacity(0.2),
                      padding: EdgeInsets.all(screen.width * 0.02),
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
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 6,
                                    offset: const Offset(2, 2),
                                  ),
                                ],
                                border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
                              ),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.asset(
                                      item['image'],
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.black.withOpacity(0.15),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 6,
                                    left: 6,
                                    right: 6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Image.asset('assets/images/ConnectBeat_coin.png', width: screen.width * 0.04),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${item['price']} 코인',
                                            style: TextStyle(
                                              fontFamily: 'GowunBatang',
                                              color: Colors.white,
                                              fontSize: screen.width * 0.03,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
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
          ),
        ],
      ),
    );
  }
}
