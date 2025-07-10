import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:connectbeat/screens/main_screen.dart';
import 'package:connectbeat/routes/app_router.dart';
import 'package:firebase_core/firebase_core.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Firebase 초기화
  await Firebase.initializeApp();

  try {
    await dotenv.load(fileName: ".env");
    final kakaoKey = dotenv.env['KAKAO_NATIVE_APP_KEY'];
    if (kakaoKey == null || kakaoKey.isEmpty) {
      throw Exception('KAKAO_NATIVE_APP_KEY가 .env 파일에 없습니다.');
    }
    KakaoSdk.init(
      nativeAppKey: kakaoKey,
    );
  } catch (e, stack) {
    // 오류 발생 시 로그 출력 후 종료
    debugPrint('초기화 오류: $e\n$stack');
    return;
  }

  runApp(const ProviderScope(child: ConnectBeatApp()));
}

class ConnectBeatApp extends StatelessWidget {
  const ConnectBeatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ConnectBeat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFFF8FC),
        fontFamily: 'Pretendard',
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black),
        ),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pinkAccent),
      ),
      home: const MainScreen(),
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
