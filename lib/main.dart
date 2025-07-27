import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:connectbeat/screens/main_screen.dart';
import 'package:connectbeat/routes/app_router.dart';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  final kakaoKey = dotenv.env['KAKAO_NATIVE_APP_KEY'];
  if (kakaoKey == null) {
    throw Exception('KAKAO_NATIVE_APP_KEY is not defined in .env file');
  }

  KakaoSdk.init(nativeAppKey: kakaoKey);

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
      navigatorObservers: [routeObserver],
    );
  }
}
