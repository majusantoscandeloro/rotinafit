import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Web Client ID (OAuth 2.0 tipo "Web") do projeto Firebase — necessário no Android
/// para o Google Sign-In retornar idToken e o Firebase Auth aceitar a credencial.
/// Mesmo valor que em google-services.json → oauth_client → client_type 3.
const _googleSignInWebClientId =
    '16511170615-nfrr5llei55ca7rfcvr34i8ldfcu2vjc.apps.googleusercontent.com';

/// Serviço de autenticação com Firebase Auth (e-mail/senha e Google).
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: _googleSignInWebClientId,
    scopes: ['email', 'profile'],
  );

  User? get currentUser => _auth.currentUser;
  String? get uid => _auth.currentUser?.uid;

  /// Stream do usuário atual (null = deslogado).
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Login com Google (Firebase Auth + Google Sign-In).
  Future<User?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;
      if (idToken == null) {
        if (kDebugMode) {
          debugPrint('AuthService: Google Sign-In idToken null. '
              'Verifique serverClientId (Web client ID) no Firebase/Google Cloud.');
        }
        return null;
      }
      final cred = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );
      final userCred = await _auth.signInWithCredential(cred);
      return userCred.user;
    } on FirebaseAuthException {
      rethrow;
    } on Exception catch (e, st) {
      if (kDebugMode) {
        debugPrint('AuthService signInWithGoogle: $e');
        debugPrint('$st');
      }
      rethrow;
    }
  }

  /// Login com e-mail e senha.
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return cred.user;
  }

  /// Registrar novo usuário com e-mail e senha.
  Future<User?> signUpWithEmailAndPassword(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return cred.user;
  }

  /// Enviar e-mail de redefinição de senha.
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Sair da conta (Firebase + Google Sign-In).
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
