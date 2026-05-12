import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';

enum AuthStatus { loading, unauthenticated, authenticated, error }

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._authService);

  final AuthService _authService;
  StreamSubscription<User?>? _subscription;

  AuthStatus _status = AuthStatus.loading;
  User? _firebaseUser;
  String? _error;

  AuthStatus get status => _status;
  User? get firebaseUser => _firebaseUser;
  String? get error => _error;
  bool get isAuthenticated => _firebaseUser != null;
  bool get firebaseEnabled => _authService.firebaseEnabled;

  Future<void> bootstrap() async {
    if (!_authService.firebaseEnabled) {
      _status = AuthStatus.error;
      _error = 'Firebase is not configured yet.';
      notifyListeners();
      return;
    }

    _firebaseUser = _authService.currentUser;
    _status = _firebaseUser == null ? AuthStatus.unauthenticated : AuthStatus.authenticated;
    notifyListeners();

    _subscription = _authService.authStateChanges().listen(
      (user) {
        _firebaseUser = user;
        _status = user == null ? AuthStatus.unauthenticated : AuthStatus.authenticated;
        _error = null;
        notifyListeners();
      },
      onError: (Object error) {
        _status = AuthStatus.error;
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  Future<UserCredential?> signIn(String email, String password) async {
    return _guard(() => _authService.signInWithEmail(email, password));
  }

  Future<UserCredential?> signUp(String name, String email, String password) async {
    return _guard(() => _authService.signUpWithEmail(email, password, name));
  }

  Future<UserCredential?> signInWithGoogle() async {
    return _guard(_authService.signInWithGoogle);
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  AppUser userFromCredential(
    User user, {
    String? fallbackName,
    String goals = 'Build strength',
    String fitnessLevel = 'Beginner',
    int daysPerWeek = 3,
  }) {
    return AppUser(
      uid: user.uid,
      name: user.displayName ?? fallbackName ?? 'GymPro Athlete',
      email: user.email ?? '',
      photoUrl: user.photoURL,
      joinDate: DateTime.now(),
      goals: goals,
      fitnessLevel: fitnessLevel,
      daysPerWeek: daysPerWeek,
    );
  }

  Future<UserCredential?> _guard(Future<UserCredential> Function() action) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();
    try {
      return await action();
    } on FirebaseAuthException catch (error) {
      _status = AuthStatus.unauthenticated;
      _error = error.message ?? error.code;
      notifyListeners();
      return null;
    } catch (error) {
      _status = AuthStatus.unauthenticated;
      _error = error.toString();
      notifyListeners();
      return null;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
