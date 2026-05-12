import 'package:flutter/material.dart';

import 'screens/active_workout_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/exercise_picker_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

class GymProApp extends StatelessWidget {
  const GymProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GymPro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      initialRoute: SplashScreen.route,
      routes: {
        SplashScreen.route: (_) => const SplashScreen(),
        OnboardingScreen.route: (_) => const OnboardingScreen(),
        AuthScreen.route: (_) => const AuthScreen(),
        HomeScreen.route: (_) => const HomeScreen(),
        ActiveWorkoutScreen.route: (_) => const ActiveWorkoutScreen(),
        ExercisePickerScreen.route: (_) => const ExercisePickerScreen(),
        ProgressScreen.route: (_) => const ProgressScreen(),
        ProfileScreen.route: (_) => const ProfileScreen(),
      },
    );
  }
}
