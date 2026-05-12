import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService({required this.firebaseEnabled});

  final bool firebaseEnabled;

  FirebaseAuth get _auth => FirebaseAuth.instance;

  Stream<User?> authStateChanges() {
    if (!firebaseEnabled) return const Stream<User?>.empty();
    return _auth.authStateChanges();
  }

  User? get currentUser => firebaseEnabled ? _auth.currentUser : null;

  Future<UserCredential> signInWithEmail(String email, String password) {
    _ensureFirebase();
    return _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
  }

  Future<UserCredential> signUpWithEmail(String email, String password, String name) async {
    _ensureFirebase();
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user?.updateDisplayName(name.trim());
    return credential;
  }

  Future<UserCredential> signInWithGoogle() async {
    _ensureFirebase();
    final account = await GoogleSignIn().signIn();
    if (account == null) {
      throw FirebaseAuthException(code: 'cancelled', message: 'Google sign-in was cancelled.');
    }

    final auth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: auth.accessToken,
      idToken: auth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    if (!firebaseEnabled) return;
    await Future.wait([
      _auth.signOut(),
      GoogleSignIn().signOut(),
    ]);
  }

  void _ensureFirebase() {
    if (!firebaseEnabled) {
      throw StateError('Firebase is not configured. Run FlutterFire configuration first.');
    }
  }
}
