import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

/// Provider que expõe o estado de autenticação (usuário atual ou null).
class AuthProvider extends ChangeNotifier {
  final AuthService _auth = AuthService();
  StreamSubscription<User?>? _subscription;

  User? _user;
  User? get user => _user;
  bool get isLoggedIn => _user != null;
  String? get uid => _user?.uid;

  AuthProvider() {
    _user = _auth.currentUser;
    _subscription = _auth.authStateChanges.listen((User? u) {
      if (_user != u) {
        _user = u;
        notifyListeners();
      }
    });
  }

  Future<User?> signIn(String email, String password) async {
    final u = await _auth.signInWithEmailAndPassword(email, password);
    _user = u;
    notifyListeners();
    return u;
  }

  /// Login com Google. Retorna null se o usuário cancelar.
  Future<User?> signInWithGoogle() async {
    final u = await _auth.signInWithGoogle();
    _user = u;
    notifyListeners();
    return u;
  }

  Future<User?> signUp(String email, String password) async {
    final u = await _auth.signUpWithEmailAndPassword(email, password);
    _user = u;
    notifyListeners();
    return u;
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email);
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
