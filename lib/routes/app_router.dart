import 'package:connectbeat/screens/chat_report_list_screen.dart';
import 'package:flutter/material.dart';

// ✅ 추가된 화면 import
import 'package:connectbeat/screens/character_screen.dart';

// 화면 import
import 'package:connectbeat/screens/login_screen.dart';
import 'package:connectbeat/screens/couple_code_screen.dart';
import 'package:connectbeat/screens/create_code_screen.dart';
import 'package:connectbeat/screens/input_code_screen.dart';
import 'package:connectbeat/screens/home_screen.dart';
import 'package:connectbeat/screens/couple_date_screen.dart';
import 'package:connectbeat/screens/setting_screen.dart';
import 'package:connectbeat/screens/couple_manage_screen.dart';
import 'package:connectbeat/screens/myprofile_setting_screen.dart';
import 'package:connectbeat/screens/splash_screen.dart';
import 'package:connectbeat/screens/main_screen.dart';
import 'package:connectbeat/screens/emotion_result_screen.dart';
import 'package:connectbeat/screens/profile_setup_screen.dart';
import 'package:connectbeat/screens/chat_room_screen.dart';
import 'package:connectbeat/models/chat_room.dart';

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
      case '/home':
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case '/couple-date':
        return MaterialPageRoute(builder: (_) => const CoupleDateScreen());
      case '/setting':
        return MaterialPageRoute(builder: (_) => const SettingScreen());
      case '/couple-manage':
        return MaterialPageRoute(builder: (_) => const CoupleManageScreen());
      case '/myprofile-setting':
        return MaterialPageRoute(builder: (_) => const MyProfileSettingScreen());
      case '/splash':
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case '/main':
        return MaterialPageRoute(builder: (_) => const MainScreen());

      case '/reportlist':
        final args = settings.arguments as Map<String, dynamic>?;
        final coupleId = args?['coupleId'] ?? 0;
        return MaterialPageRoute(
          builder: (_) => ChatReportListScreen(coupleId: coupleId),
        );

      case '/emotion-result':
        final args = settings.arguments;
        if (args is String) {
          return MaterialPageRoute(
            builder: (_) => EmotionResultScreen(chatSessionId: args),
          );
        } else {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text("⚠️ chatSessionId가 전달되지 않았습니다.")),
            ),
          );
        }

    // ✅ 둘 다 유지: 캐릭터 & 주제 선택
      case '/character':
        return MaterialPageRoute(builder: (_) => const CharacterScreen());
    // case '/topic-select':
    //   return MaterialPageRoute(builder: (_) => const TopicSelectScreen());

    // ✅ 채팅방 화면 라우트
      case '/chat':
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => ChatRoomScreen(
            room: args['room'] as ChatRoom,
            currentUserId: args['currentUserId'] as String,
          ),
        );

    // ✅ 프로필 설정 화면 라우트
      case '/profile-setup':
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => ProfileSetupScreen(
            nickname: args['nickname'] as String,
            profileImageUrl: args['profileImageUrl'] as String,
          ),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const UnknownRouteScreen(),
        );
    }
  }
}

// 404 처리 화면
class UnknownRouteScreen extends StatelessWidget {
  const UnknownRouteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('404 - 페이지를 찾을 수 없습니다')),
    );
  }
}
