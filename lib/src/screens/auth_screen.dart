import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/onboarding_provider.dart';
import '../providers/workout_provider.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  static const route = '/auth';

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _signup = false;
  bool _busy = false;

  Future<void> _submit({bool google = false}) async {
    if (!google && !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    final auth = context.read<AuthProvider>();
    final onboarding = context.read<OnboardingProvider>();
    final store = context.read<FirestoreService>();
    final credential = google
        ? await auth.signInWithGoogle()
        : _signup
            ? await auth.signUp(_name.text, _email.text, _password.text)
            : await auth.signIn(_email.text, _password.text);

    final user = credential?.user;
    if (user != null) {
      await store.upsertUser(
        auth.userFromCredential(
          user,
          fallbackName: _name.text,
          goals: onboarding.goal,
          fitnessLevel: onboarding.fitnessLevel,
          daysPerWeek: onboarding.daysPerWeek,
        ),
      );
      if (mounted) {
        context.read<WorkoutProvider>().bind(user.uid);
        Navigator.pushReplacementNamed(context, HomeScreen.route);
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.firebaseEnabled) {
      return const Scaffold(
        body: EmptyState(
          icon: Icons.cloud_off,
          title: 'Firebase setup needed',
          message: 'Run FlutterFire configuration and add platform Firebase files before signing in.',
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.fitness_center, color: AppTheme.accent, size: 56),
                  const SizedBox(height: 16),
                  Text(_signup ? 'Create GymPro account' : 'Welcome back', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 24),
                  if (_signup) ...[
                    TextFormField(
                      controller: _name,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter your name' : null,
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) => value != null && value.contains('@') ? null : 'Enter a valid email',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: (value) => value != null && value.length >= 6 ? null : 'Use at least 6 characters',
                  ),
                  if (auth.error != null) ...[
                    const SizedBox(height: 12),
                    Text(auth.error!, style: const TextStyle(color: Colors.redAccent)),
                  ],
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: _busy ? null : () => _submit(),
                    child: _busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(_signup ? 'Sign up' : 'Log in'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => _submit(google: true),
                    icon: const Icon(Icons.g_mobiledata, size: 28),
                    label: const Text('Continue with Google'),
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: () => setState(() => _signup = !_signup),
                    child: Text(_signup ? 'Already have an account? Log in' : 'New here? Create account'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
