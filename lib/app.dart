import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/services/storage_service.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_screen.dart';

class LipidLogApp extends ConsumerWidget {
  const LipidLogApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if user has completed onboarding
    final hasProfile = StorageService.getUserProfile() != null;

    return MaterialApp(
      title: 'LipidLog',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: hasProfile ? const HomeScreen() : const OnboardingScreen(),
    );
  }
}
