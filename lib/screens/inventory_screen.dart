import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/inventory_provider.dart';
import '../core/constants.dart';
import '../services/store_service.dart';
import '../models/store_models.dart';
import '../models/inventory_models.dart';
import '../providers/coin_provider.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  int _selectedIndex = 0;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _clothesKey = GlobalKey();
  final GlobalKey _backgroundKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // 화면 진입 시 서버에서 인벤토리 및 현재 데코 불러오기
    Future.microtask(() async {
      await ref.read(inventoryProvider.notifier).fetchInventory();
      await ref.read(currentDecorationProvider.notifier).fetchCurrentDecoration();
    });
  }

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

  Widget _buildSectionButton(String title, int index) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _scrollToSection(index == 0 ? _clothesKey : _backgroundKey);
          setState(() => _selectedIndex = index);
        },
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
                  color: Colors.black),
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

  Widget _buildItemGrid(List<InventoryItemDTO> items, String category) {
    final currentDecoration = ref.watch(currentDecorationProvider);

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
        final inventoryItem = items[index];
        final item = inventoryItem.item;

        final isEquipped = (category == 'CLOTHES' &&
            currentDecoration?.clothesItem?.id == item.id) ||
            (category == 'BACKGROUND' &&
                currentDecoration?.backgroundItem?.id == item.id);

        return Container(
          decoration: BoxDecoration(
            color: Colors.white, // 배경 화이트
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(2, 2),
              ),
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
              Text(
                item.name,
                style: const TextStyle(
                  fontFamily: 'GowunBatang',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${item.price} 코인',
                style: const TextStyle(
                  fontFamily: 'GowunBatang',
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isEquipped
                      ? null
                      : () async {
                    await ref
                        .read(inventoryProvider.notifier)
                        .applyItem(item.id);
                    await ref
                        .read(currentDecorationProvider.notifier)
                        .fetchCurrentDecoration();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    isEquipped ? Colors.grey : const Color(0xfffdf1ff),
                    foregroundColor: Colors.black,
                    minimumSize: const Size(50, 30),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 6,
                    shadowColor: Colors.pink.withOpacity(0.2),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: Text(isEquipped ? '착용중' : '착용'),
                ),
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
    final inventory = ref.watch(inventoryProvider);

    final clothesItems =
    inventory.where((e) => e.item.category == 'CLOTHES').toList();
    final backgroundItems =
    inventory.where((e) => e.item.category == 'BACKGROUND').toList();

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
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Text(
                    '내 인벤토리',
                    style: TextStyle(
                        fontFamily: 'GowunBatang',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                ),
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
                Expanded(
                  child: inventory.isEmpty
                      ? const Center(
                    child: Text(
                      '구매한 아이템이 없습니다.',
                      style: TextStyle(
                          fontFamily: 'GowunBatang',
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  )
                      : SingleChildScrollView(
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
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '옷',
                                  style: TextStyle(
                                      fontFamily: 'GowunBatang',
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black),
                                ),
                                const SizedBox(height: 8),
                                _buildItemGrid(clothesItems, 'CLOTHES'),
                              ],
                            ),
                          ),
                          // 배경 섹션
                          Container(
                            key: _backgroundKey,
                            margin: const EdgeInsets.only(bottom: 24),
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '배경',
                                  style: TextStyle(
                                      fontFamily: 'GowunBatang',
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black),
                                ),
                                const SizedBox(height: 8),
                                _buildItemGrid(
                                    backgroundItems, 'BACKGROUND'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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
