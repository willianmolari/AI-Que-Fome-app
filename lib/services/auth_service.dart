import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/account_info.dart';

/// Login com Google usando Firebase Auth.
class AuthService {
  AuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _google = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _google;

  static Future<void>? _initialization;

  User? get currentUser => _auth.currentUser;

  Future<void> _ensureInitialized() {
    return _initialization ??= _google.initialize().catchError((error) {
      _initialization = null;
      throw error;
    });
  }

  Future<AccountInfo> signInWithGoogle() async {
    try {
      await _ensureInitialized();

      final googleUser = await _google.authenticate();
      final idToken = googleUser.authentication.idToken;
      if (idToken == null) {
        throw const AuthFailure('Não foi possível obter o token do Google.');
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        throw const AuthFailure('Não foi possível obter a conta do Firebase.');
      }

      return AccountInfo(
        displayName: user.displayName ??
            googleUser.displayName ??
            'Usuário Google',
        email: user.email ?? googleUser.email,
        photoUrl: user.photoURL ?? googleUser.photoUrl,
        uid: user.uid,
      );
    } on AuthFailure {
      rethrow;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthFailure('Login cancelado.');
      }
      throw AuthFailure('Falha no login com Google: ${e.description}');
    } catch (error) {
      throw AuthFailure(
        'Falha ao entrar com Google. Verifique o google-services.json, '
        'a SHA-1 cadastrada no Firebase e se o provedor Google está ativado. '
        'Detalhe: $error',
      );
    }
  }

  Future<void> signOut() async {
    await Future.wait([
      _google.signOut(),
      _auth.signOut(),
    ]);
  }
}

class AuthFailure implements Exception {
  final String message;
  const AuthFailure(this.message);

  @override
  String toString() => message;
}
