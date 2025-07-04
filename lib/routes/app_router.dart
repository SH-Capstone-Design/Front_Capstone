import 'package:flutter/material.dart';
import 'package:connectbeat/screens/login_screen.dart';
import 'package:connectbeat/screens/create_code_screen.dart';
import 'package:connectbeat/screens/couple_code_screen.dart';
import 'package:connectbeat/screens/input_code_screen.dart';
import 'package:connectbeat/screens/profile_setup_screen.dart'; // 추가

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/couple-code':
        return MaterialPageRoute(builder: (_) => const CoupleCodeScreen());
      case '/create-code':
        return MaterialPageRoute(builder: (_) => const CreateCodeScreen());
      case '/input-code':
        return MaterialPageRoute(builder: (_) => const InputCodeScreen());
      case '/profile_setup':
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => ProfileSetupScreen(
            nickname: args['nickname'],
            profileImageUrl: args['profileImageUrl'],
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const UnknownRouteScreen(),
        );
    }
  }
}

class UnknownRouteScreen extends StatelessWidget {
  const UnknownRouteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('404 - 페이지를 찾을 수 없습니다')),
    );
  }
}
