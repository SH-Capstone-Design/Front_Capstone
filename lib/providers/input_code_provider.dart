import 'package:flutter_riverpod/flutter_riverpod.dart';

final codeInputProvider = StateProvider<String>((ref) => '');

final codeLoadingProvider = StateProvider<bool>((ref) => false);

final codeErrorProvider = StateProvider<String?>((ref) => null);