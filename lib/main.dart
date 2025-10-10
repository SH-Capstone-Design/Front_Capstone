import 'package:connectbeat/screens/couple_code_screen.dart';
import 'package:connectbeat/screens/emotion_result_screen.dart';
import 'package:connectbeat/screens/main_screen.dart';
import 'package:connectbeat/models/chat_room.dart';
import 'package:connectbeat/screens/chat_room_screen.dart';
import 'package:connectbeat/screens/splash_screen.dart';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:connectbeat/routes/app_router.dart';
import 'package:logging/logging.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
RouteObserver<ModalRoute<void>>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // ✅ 로그 설정 추가
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
      // 초기 화면: Splash
      home: const SplashScreen(),
      // 디버깅 시 채팅방 화면을 바로 띄우고 싶다면 아래 코드 주석 해제
      // home: ChatRoomScreen(
      //   room: ChatRoom(chatSessionId: 'debug-session'), // 더미 세션
      //   currentUserId: 'debug-user',
      // ),
      onGenerateRoute: AppRouter.generateRoute, // AppRouter로 모든 라우트 처리
      navigatorObservers: [routeObserver],
    );
  }
}
