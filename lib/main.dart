import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'src/app.dart';
import 'src/providers/auth_provider.dart';
import 'src/providers/onboarding_provider.dart';
import 'src/providers/subscription_provider.dart';
import 'src/providers/workout_provider.dart';
import 'src/services/auth_service.dart';
import 'src/services/firestore_service.dart';
import 'src/services/purchase_service.dart';
import 'src/services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Object? firebaseError;
  try {
    await Firebase.initializeApp();
  } catch (error) {
    firebaseError = error;
  }

  runApp(
    MultiProvider(
      providers: [
        Provider<Object?>.value(value: firebaseError),
        Provider(create: (_) => AuthService(firebaseEnabled: firebaseError == null)),
        Provider(create: (_) => FirestoreService(firebaseEnabled: firebaseError == null)),
        Provider(create: (_) => StorageService(firebaseEnabled: firebaseError == null)),
        Provider(create: (_) => PurchaseService()),
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
        ChangeNotifierProvider(
          create: (context) => SubscriptionProvider(context.read<PurchaseService>())..load(),
        ),
        ChangeNotifierProvider(
          create: (context) => AuthProvider(context.read<AuthService>())..bootstrap(),
        ),
        ChangeNotifierProvider(
          create: (context) => WorkoutProvider(
            firestoreService: context.read<FirestoreService>(),
          ),
        ),
      ],
      child: const GymProApp(),
    ),
  );
}
