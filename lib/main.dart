import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/main_screen.dart';
import 'app_router.dart';

void main() {
  runApp(
    const ProviderScope(child: MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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