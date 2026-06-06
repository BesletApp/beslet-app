import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'user_provider.dart';

final localeProvider = Provider<Locale>((ref) {
  final userAsync = ref.watch(userProvider);
  final lang = userAsync.valueOrNull?.lang ?? 'en';
  return Locale(lang);
});
