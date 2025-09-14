import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectbeat/core/constants.dart';
import 'package:connectbeat/providers/couple_date_provider.dart';
import 'package:connectbeat/widgets/bottom_bar.dart';
import 'package:connectbeat/main.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with RouteAware {
  int _currentIndex = 2;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // RouteObserver 등록
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    // RouteObserver 해제
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // CoupleDateScreen이나 다른 화면에서 돌아왔을 때
    ref.invalidate(coupleDDayProvider);

    // 홈 화면이므로 하단바 인덱스를 2로 갱신
    setState(() {
      _currentIndex = 2;
    });
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/history');
        break;
      case 1:
        Navigator.pushNamed(context, '/character');
        break;
      case 2:
      // 현재 홈
        break;
      case 3:
        Navigator.pushNamed(context, '/setting');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dDayAsyncValue = ref.watch(coupleDDayProvider);
    final size = MediaQuery.of(context).size;

    return WillPopScope(
      onWillPop: () async {
        // 뒤로가기 막기
        return false;
      },
      child: Scaffold(
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
                    SizedBox(height: size.height * 0.02),
                    SizedBox(
                      height: size.height * 0.15,
                      child: Image.asset(AppConstants.logoPath),
                    ),
                    SizedBox(height: size.height * 0.05),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/create-chat');
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
                    SizedBox(height: size.height * 0.015),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        width: size.width * 0.5,
                        padding: EdgeInsets.symmetric(vertical: size.height * 0.015),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE6F4),
                          borderRadius: BorderRadius.circular(size.width * 0.1),
                        ),
                        child: Center(
                          child: dDayAsyncValue.when(
                            data: (dDayText) => Text(
                              dDayText,
                              style: const TextStyle(fontSize: 16),
                            ),
                            loading: () => const CircularProgressIndicator(),
                            error: (_, __) => const Text('에러 발생'),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: size.height * 0.03),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/backgroundCharacter');
                      },
                      child: Container(
                        width: double.infinity,
                        height: size.height * 0.25,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey, width: 2),
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
                    SizedBox(height: size.height * 0.05),
                  ],
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: BottomBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
        ),
      ),
    );
  }
}
