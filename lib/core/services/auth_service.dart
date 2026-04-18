import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService extends ChangeNotifier {
  AuthService() {
    _auth.authStateChanges().listen((user) {
      if (_currentUser?.uid != user?.uid) {
        _currentUser = user;
        notifyListeners();
      }
    });
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;

  User? get currentUser => _auth.currentUser ?? _currentUser;
  bool get isSignedIn => currentUser != null;

  Future<void> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    final credentials = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    _currentUser = credentials.user;
    notifyListeners();
  }

  Future<void> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    final credentials = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    _currentUser = credentials.user;
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      throw Exception('Google sign in cancelled');
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final result = await _auth.signInWithCredential(credential);
    _currentUser = result.user;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
    _currentUser = null;
    notifyListeners();
  }
}
