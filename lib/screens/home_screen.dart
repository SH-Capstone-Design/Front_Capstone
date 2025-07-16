import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectbeat/core/constants.dart';
import 'package:connectbeat/providers/couple_date_provider.dart'; // Provider import

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dDayAsyncValue = ref.watch(coupleDDayProvider);

    final size = MediaQuery.of(context).size;
    final logoHeight = size.height * 0.15;
    final topPadding = size.height * 0.02;
    final spacingSmall = size.height * 0.015;
    final spacingMedium = size.height * 0.03;
    final spacingLarge = size.height * 0.05;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppConstants.backgroundPath),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.06),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: topPadding),

                  // 로고
                  SizedBox(
                    height: logoHeight,
                    child: Image.asset(
                      AppConstants.logoPath,
                      fit: BoxFit.contain,
                    ),
                  ),

                  SizedBox(height: spacingLarge),

                  // 오늘 우리의 10분
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/10min_chat');
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: size.height * 0.06),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE6F4),
                        borderRadius: BorderRadius.circular(size.width * 0.06),
                      ),
                      child: const Center(
                        child: Text(
                          '오늘 우리의 10분',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: spacingSmall),

                  // 커플 디데이
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () async {
                        await Navigator.pushNamed(context, '/coupledate');
                        ref.invalidate(coupleDDayProvider);
                      },
                      child: Container(
                        width: size.width * 0.5,
                        padding: EdgeInsets.symmetric(
                          vertical: size.height * 0.015,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE6F4),
                          borderRadius: BorderRadius.circular(size.width * 0.1),
                        ),
                        child: Center(
                          child: dDayAsyncValue.when(
                            data: (dDayText) => Text(
                              dDayText,
                              style: const TextStyle(fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                            loading: () => const CircularProgressIndicator(),
                            error: (_, __) => const Text('에러 발생'),
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: spacingMedium),

                  // 캐릭터 성장 프레임
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/backgroundCharacter');
                    },
                    child: Container(
                      width: double.infinity,
                      height: size.height * 0.25,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(size.width * 0.03),
                      ),
                      child: const Center(
                        child: Text(
                          '성장시킬 캐릭터 자리',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: spacingLarge),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
