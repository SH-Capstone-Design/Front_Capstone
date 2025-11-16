import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/coin_provider.dart';
import '../providers/couple_date_provider.dart';
import '../providers/user_provider.dart';
import '../providers/couple_provider.dart';
import '../models/store_models.dart';

class BackgroundPreviewScreen extends ConsumerWidget {
  final StoreItemDTO item; // DB에서 가져온 배경 아이템

  const BackgroundPreviewScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    final coupleAsync = ref.watch(coupleStatusProvider);
    final coupleDate = ref.watch(coupleDateProvider);
    final coin = ref.watch(coinProvider);

    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${item.name} 미리보기',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // 배경 이미지
          Positioned.fill(
            child: Image.network(
              item.assetUrl ?? item.imageUrl,
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(height: kToolbarHeight + 16),

                  // 커플 & 유저 정보
                  userAsync.when(
                    data: (user) {
                      return coupleAsync.when(
                        data: (couple) {
                          final partnerNickname = couple?['partnerNickname'] ?? '파트너 없음';
                          final userNickname = user?['nickname'] ?? '닉네임 없음';
                          String dDayText = '사귄 날짜를 설정해주세요';
                          if (coupleDate != null) {
                            final days = DateTime.now().difference(coupleDate).inDays + 1;
                            dDayText = '우리가 만난지 $days일 🩷';
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '$userNickname ❤️ $partnerNickname',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dDayText,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 12),
                              // 코인 정보
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Image.asset(
                                    'assets/images/ConnectBeat_coin.png',
                                    width: 30,
                                    height: 30,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$coin 개',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                        loading: () => const SizedBox(),
                        error: (err, st) => const SizedBox(),
                      );
                    },
                    loading: () => const SizedBox(),
                    error: (err, st) => const SizedBox(),
                  ),

                  const Spacer(),

                  // 중앙 하단: 아이템 설명
                  if (item.description != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Center(
                        child: Text(
                          item.description!,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
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
