import 'package:flutter/material.dart';
import '../models/store_models.dart';

class PreviewScreen extends StatelessWidget {
  final StoreItemDTO item;

  const PreviewScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    const infoFontSize = 18.0;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          '${item.name} 미리보기',
          style: const TextStyle(
            fontFamily: 'GowunBatang',
            fontSize: 22,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // 배경
          Positioned.fill(
            child: Image.asset(
              'assets/images/fiting_room.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(), // 위쪽 공간
                  // 캐릭터
                  Expanded(
                    flex: 4,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Image.network(
                        item.assetUrl ?? item.imageUrl,
                        fit: BoxFit.contain,
                        height: screenHeight * 0.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 설명
                  Text(
                    item.description ?? '',
                    style: const TextStyle(
                      fontFamily: 'GowunBatang',
                      fontSize: infoFontSize,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: screenHeight * 0.05),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
