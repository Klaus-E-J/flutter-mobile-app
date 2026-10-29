import 'package:flutter/foundation.dart';

import '../data/auth_repository.dart';
import '../data/user_profile.dart';

/// ViewModel para a tela de autenticação e gerenciamento de sessão,
/// seguindo o padrão MVVM recomendado no Flutter.
class AuthViewModel extends ChangeNotifier {
  AuthViewModel({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository();

  final AuthRepository _authRepository;

  UserProfile? _profile;
  UserProfile? get profile => _profile;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  bool get isAuthenticated => _authRepository.isAuthenticated;

  /// Autentica o professor com e-mail e senha.
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      _errorMessage = 'Informe um endereço de e-mail válido.';
      notifyListeners();
      return false;
    }
    if (password.trim().isEmpty) {
      _errorMessage = 'Informe sua senha.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    try {
      _profile = await _authRepository.signIn(
        email: cleanEmail,
        password: password,
      );
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Registra um novo professor.
  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    String? school,
  }) async {
    final cleanName = name.trim();
    final cleanEmail = email.trim();

    if (cleanName.isEmpty) {
      _errorMessage = 'Informe seu nome completo.';
      notifyListeners();
      return false;
    }
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      _errorMessage = 'Informe um endereço de e-mail válido.';
      notifyListeners();
      return false;
    }
    if (password.length < 6) {
      _errorMessage = 'A senha deve ter pelo menos 6 caracteres.';
      notifyListeners();
      return false;
    }
    if (password != confirmPassword) {
      _errorMessage = 'As senhas não coincidem.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    try {
      _profile = await _authRepository.signUp(
        name: cleanName,
        email: cleanEmail,
        password: password,
        school: school,
      );
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Autentica como convidado (acesso rápido anônimo).
  Future<bool> signInAsGuest() async {
    _setLoading(true);
    try {
      _profile = await _authRepository.signInAsGuest();
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Envia e-mail de recuperação de senha.
  Future<bool> sendPasswordReset(String email) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      _errorMessage = 'Informe o e-mail cadastrado para redefinir a senha.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    try {
      await _authRepository.sendPasswordReset(cleanEmail);
      _errorMessage = null;
      _successMessage = 'Link de redefinição enviado para $cleanEmail.';
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Encerra a sessão atual.
  Future<void> signOut() async {
    await _authRepository.signOut();
    _profile = null;
    notifyListeners();
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
