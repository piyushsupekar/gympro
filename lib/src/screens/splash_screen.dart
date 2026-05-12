import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/onboarding_provider.dart';
import '../providers/workout_provider.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const route = '/';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(_decide());
  }

  Future<void> _decide() async {
    final onboarding = context.read<OnboardingProvider>();
    if (!onboarding.loaded) await onboarding.load();
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    if (!onboarding.isComplete) {
      Navigator.pushReplacementNamed(context, OnboardingScreen.route);
      return;
    }
    if (auth.isAuthenticated && auth.firebaseUser != null) {
      context.read<WorkoutProvider>().bind(auth.firebaseUser!.uid);
      Navigator.pushReplacementNamed(context, HomeScreen.route);
    } else {
      Navigator.pushReplacementNamed(context, AuthScreen.route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppTheme.accent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.fitness_center, size: 48, color: Colors.white),
            ),
            const SizedBox(height: 18),
            Text('GymPro', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('Train. Track. Progress.', style: TextStyle(color: AppTheme.textMuted)),
            const SizedBox(height: 28),
            const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2)),
          ],
        ),
      ),
    );
  }
}
