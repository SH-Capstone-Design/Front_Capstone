import 'package:connectbeat/models/inventory_models.dart';
import 'package:connectbeat/screens/backgroundpreview_screen.dart';
import 'package:connectbeat/screens/preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../models/store_models.dart';
import '../providers/coin_provider.dart';
import '../providers/store_provider.dart';
import '../providers/inventory_provider.dart'; // 🔹 인벤토리 provider
import '../services/store_service.dart'; // 🔹 StoreService import
import '../widgets/banner_slider.dart';

class CharacterScreen extends ConsumerStatefulWidget {
  const CharacterScreen({super.key});

  @override
  ConsumerState<CharacterScreen> createState() => _CharacterScreenState();
}

class _CharacterScreenState extends ConsumerState<CharacterScreen> {
  final ScrollController _scrollController = ScrollController();
  int _selectedIndex = 0;

  final GlobalKey _clothesKey = GlobalKey();
  final GlobalKey _backgroundKey = GlobalKey();

  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final backgroundOffset = _backgroundKey.currentContext
          ?.findRenderObject()
          ?.getTransformTo(null)
          .getTranslation()
          .y ??
          double.infinity;

      if (_scrollController.offset >= backgroundOffset - 150) {
        setState(() => _selectedIndex = 1);
      } else {
        setState(() => _selectedIndex = 0);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildSectionButton(String title, int index) {
    final bool isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () =>
            _scrollToSection(index == 0 ? _clothesKey : _backgroundKey),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'GowunBatang',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Stack(
              alignment: Alignment.center,
              children: [
                Container(height: 2, width: 120, color: Colors.black12),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 2,
                  width: isSelected ? 120 : 0,
                  color: const Color(0xFFFDAAFF),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildItemGrid(List<StoreItemDTO> items) {
    final inventory = ref.watch(inventoryProvider); // 인벤토리 상태 확인

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(8),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.6,
      ),
      itemBuilder: (context, index) {
        final item = items[index];

        // 🔹 이미 구매했는지 체크
        final isPurchased = inventory.any((inv) => inv.item.id == item.id);

        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(2, 2))
            ],
          ),
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Image.network(
                    item.imageUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Text(item.name,
                  style: const TextStyle(
                      fontFamily: 'GowunBatang',
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
              Text('${item.price} 코인',
                  style: const TextStyle(
                      fontFamily: 'GowunBatang',
                      fontSize: 12,
                      color: Colors.black54)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      if (item.category == 'BACKGROUND') {
                        // 배경 미리보기
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BackgroundPreviewScreen(item: item),
                          ),
                        );
                      } else {
                        // 옷 미리보기
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PreviewScreen(item: item),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xfffdf1ff),
                      minimumSize: const Size(50, 28),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text('미리보기', style: TextStyle(fontSize: 10)),
                  ),

                  ElevatedButton(
                    onPressed: isPurchased
                        ? null // 이미 구매한 경우 버튼 비활성화
                        : () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('구매 확인'),
                          content: Text('${item.name}을(를) ${item.price} 코인에 구매하시겠습니까?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('취소'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('확인'),
                            ),
                          ],
                        ),
                      );

                      if (confirm != true) return; // 사용자가 취소하면 종료

                      final coinNotifier = ref.read(coinProvider.notifier);
                      final inventoryNotifier = ref.read(inventoryProvider.notifier);

                      if (coinNotifier.state >= item.price) {
                        try {
                          await StoreService().purchaseItem(item.id);

                          // 코인 차감
                          coinNotifier.state -= item.price;

                          // 인벤토리에 추가
                          inventoryNotifier.addItemFromPurchase(
                            InventoryItemDTO(
                              inventoryId: 0,
                              item: item,
                              acquiredAt: DateTime.now(),
                            ),
                          );

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('구매 완료!')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('구매 실패: $e')),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('코인이 부족합니다.')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPurchased ? Colors.grey : const Color(0xfffdf1ff),
                      minimumSize: const Size(50, 28),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      isPurchased ? '구매 완료' : '구매',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final coin = ref.watch(coinProvider);
    final storeItemsAsync = ref.watch(storeItemsProvider);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              AppConstants.backgroundPath,
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // 상단 코인 표시
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/ConnectBeat_coin.png',
                            width: 24,
                            height: 24,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$coin',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        '캐릭터 상점',
                        style: TextStyle(
                          fontFamily: 'GowunBatang',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 24),
                    ],
                  ),
                ),

                // 🔹 배너 슬라이더
                const BannerSlider(
                  imagePaths: [
                    'assets/images/banner1.png',
                    'assets/images/banner2.png',
                  ],
                  height: 180,
                ),

                const SizedBox(height: 16),

                // 🔹 카테고리 버튼
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildSectionButton('옷', 0),
                      const SizedBox(width: 12),
                      _buildSectionButton('배경', 1),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 🔹 스크롤 영역
                Expanded(
                  child: storeItemsAsync.when(
                    data: (items) {
                      final clothesItems = items
                          .where((e) =>
                      e.category == 'CLOTHES' &&
                          !e.imageUrl.contains('cloth_0'))
                          .toList();
                      final backgroundItems =
                      items.where((e) => e.category == 'BACKGROUND'&& !e.imageUrl.contains('background_0')).toList();

                      return SingleChildScrollView(
                        controller: _scrollController,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 옷 섹션
                              Container(
                                key: _clothesKey,
                                margin: const EdgeInsets.only(bottom: 24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '옷',
                                      style: TextStyle(
                                        fontFamily: 'GowunBatang',
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF000000),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildItemGrid(clothesItems),
                                  ],
                                ),
                              ),
                              // 배경 섹션
                              Container(
                                key: _backgroundKey,
                                margin: const EdgeInsets.only(bottom: 24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '배경',
                                      style: TextStyle(
                                        fontFamily: 'GowunBatang',
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF000000),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildItemGrid(backgroundItems),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    loading: () =>
                    const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Center(child: Text('에러 발생: $err')),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
