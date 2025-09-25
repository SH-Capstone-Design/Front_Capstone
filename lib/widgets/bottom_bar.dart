import 'package:flutter/material.dart';

class BottomBar extends StatefulWidget {
  final int currentIndex;
  final void Function(int) onTap;

  const BottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _selectedIndex = 0;

  final List<IconData> items = [
    Icons.chat,
    Icons.emoji_emotions,
    Icons.home,
    Icons.settings,
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.currentIndex;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<double>(begin: _selectedIndex.toDouble(), end: _selectedIndex.toDouble())
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(covariant BottomBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedIndex != widget.currentIndex) {
      _animateTo(widget.currentIndex);
    }
  }

  void _animateTo(int newIndex) {
    _animation = Tween<double>(begin: _selectedIndex.toDouble(), end: newIndex.toDouble())
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _selectedIndex = newIndex;
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    final barHeight = (height * 0.08).clamp(60, 80).toDouble();
    final indicatorHeight = (barHeight * 0.6).clamp(40, 50).toDouble();
    final indicatorWidth = indicatorHeight * 1.8; // 길쭉한 타원
    final iconSize = (barHeight * 0.35).clamp(24, 30).toDouble();

    return SizedBox(
      height: barHeight,
      child: Stack(
        children: [
          // 배경
          Container(
            height: barHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6)],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          // indicator (선택된 버튼 배경)
          AnimatedBuilder(
            animation: _animation,
            builder: (_, __) {
              return Positioned(
                bottom: barHeight * 0.2,
                left: (width / items.length) * _animation.value +
                    (width / items.length - indicatorWidth) / 2,
                child: Container(
                  width: indicatorWidth,
                  height: indicatorHeight,
                  decoration: BoxDecoration(
                    color: Colors.pink.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(indicatorHeight / 2), // 타원 끝 둥글게
                  ),
                ),
              );
            },
          ),
          // 아이콘 row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final selected = index == _selectedIndex;
              return GestureDetector(
                onTap: () {
                  widget.onTap(index);
                  _animateTo(index);
                },
                child: SizedBox(
                  width: width / items.length,
                  height: barHeight,
                  child: Icon(
                    items[index],
                    size: iconSize,
                    color: selected ? Colors.pink : Colors.grey,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
