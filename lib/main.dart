import 'package:connectbeat/screens/splash_screen.dart';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:connectbeat/routes/app_router.dart';
import 'package:logging/logging.dart';

// ✅ 글로벌 키 선언
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // ✅ 로그 설정
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('[${record.level.name}] ${record.loggerName}: ${record.message}');
  });

  final kakaoKey = dotenv.env['KAKAO_NATIVE_APP_KEY'];
  if (kakaoKey == null) {
    throw Exception('KAKAO_NATIVE_APP_KEY is not defined in .env file');
  }

  KakaoSdk.init(nativeAppKey: kakaoKey);

  // ✅ 현재 기기의 Key Hash 출력
  String keyHash = await KakaoSdk.origin;
  print('📍 현재 앱 해시키(Key Hash): $keyHash');

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
      // ✅ 글로벌 키 적용
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: messengerKey,
      home: const SplashScreen(),
      onGenerateRoute: AppRouter.generateRoute,
      navigatorObservers: [routeObserver],
    );
  }
}
