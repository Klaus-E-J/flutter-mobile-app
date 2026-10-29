import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_service.dart';

/// Serviço que encapsula operações do Firebase Authentication
/// e traduz mensagens de erro para o usuário.
class AuthService {
  AuthService({this.auth});

  final FirebaseAuth? auth;

  FirebaseAuth? get _effectiveAuth {
    if (auth != null) return auth;
    if (FirebaseService.isInitialized) return FirebaseService.auth;
    if (Firebase.apps.isNotEmpty) return FirebaseAuth.instance;
    return null;
  }

  Stream<User?> get authStateChanges =>
      _effectiveAuth?.authStateChanges() ?? const Stream.empty();

  User? get currentUser => _effectiveAuth?.currentUser;

  bool get isAuthenticated => currentUser != null;

  bool get isAnonymous => currentUser?.isAnonymous ?? true;

  /// Autentica com e-mail e senha.
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final auth = _effectiveAuth;
    if (auth == null) {
      throw const AuthException('Firebase Authentication não está inicializado.');
    }

    try {
      return await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_translateFirebaseErrorCode(e.code, e.message));
    } catch (e) {
      throw AuthException('Ocorreu um erro inesperado ao autenticar: $e');
    }
  }

  /// Cria uma nova conta com e-mail e senha.
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final auth = _effectiveAuth;
    if (auth == null) {
      throw const AuthException('Firebase Authentication não está inicializado.');
    }

    try {
      return await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_translateFirebaseErrorCode(e.code, e.message));
    } catch (e) {
      throw AuthException('Ocorreu um erro inesperado ao criar a conta: $e');
    }
  }

  /// Autentica como convidado (sessão anônima).
  Future<UserCredential> signInAnonymously() async {
    final auth = _effectiveAuth;
    if (auth == null) {
      throw const AuthException('Firebase Authentication não está inicializado.');
    }

    try {
      return await auth.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_translateFirebaseErrorCode(e.code, e.message));
    } catch (e) {
      throw AuthException('Não foi possível iniciar o acesso convidado: $e');
    }
  }

  /// Envia e-mail de recuperação de senha.
  Future<void> sendPasswordResetEmail(String email) async {
    final auth = _effectiveAuth;
    if (auth == null) {
      throw const AuthException('Firebase Authentication não está inicializado.');
    }

    try {
      await auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_translateFirebaseErrorCode(e.code, e.message));
    } catch (e) {
      throw AuthException('Não foi possível enviar o e-mail de recuperação: $e');
    }
  }

  /// Encerra a sessão atual.
  Future<void> signOut() async {
    final auth = _effectiveAuth;
    if (auth != null) {
      await auth.signOut();
    }
  }

  /// Tradução de erros comuns do Firebase Auth para português claro.
  static String _translateFirebaseErrorCode(String code, String? defaultMessage) {
    switch (code) {
      case 'invalid-email':
        return 'O endereço de e-mail informado não é válido.';
      case 'user-disabled':
        return 'Esta conta de usuário foi desativada.';
      case 'user-not-found':
        return 'Nenhum usuário cadastrado com este e-mail.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-mail ou senha incorretos. Verifique suas credenciais.';
      case 'email-already-in-use':
        return 'Este e-mail já está sendo utilizado por outra conta.';
      case 'operation-not-allowed':
        return 'A autenticação por e-mail e senha não está habilitada.';
      case 'weak-password':
        return 'A senha informada é fraca. Crie uma senha com pelo menos 6 caracteres.';
      case 'too-many-requests':
        return 'Muitas tentativas consecutivas. Aguarde alguns instantes e tente novamente.';
      case 'network-request-failed':
        return 'Falha de conexão com a internet. Verifique sua rede e tente novamente.';
      default:
        return defaultMessage ?? 'Erro de autenticação ($code). Tente novamente.';
    }
  }
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
