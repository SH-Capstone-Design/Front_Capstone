import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 서버에서 내려준 로그인한 유저의 userId를 저장하는 Provider
final currentUserProvider = StateProvider<String?>((ref) => null);
