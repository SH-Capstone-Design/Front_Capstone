import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/google_auth_service.dart';

final googleAuthProvider = Provider<GoogleAuthService>((ref) {
  return GoogleAuthService.instance;
});
