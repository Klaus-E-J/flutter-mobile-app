import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/firebase_service.dart';
import 'user_profile.dart';

/// Repositório de autenticação e gerenciamento de perfil do professor.
class AuthRepository {
  AuthRepository({
    AuthService? authService,
    this.firestore,
  })  : _authService = authService ?? AuthService();

  final AuthService _authService;
  final FirebaseFirestore? firestore;

  FirebaseFirestore? get _effectiveFirestore {
    if (firestore != null) return firestore;
    if (FirebaseService.isInitialized) return FirebaseService.firestore;
    if (Firebase.apps.isNotEmpty) return FirebaseFirestore.instance;
    return null;
  }

  Stream<User?> get authStateChanges => _authService.authStateChanges;

  User? get currentFirebaseUser => _authService.currentUser;

  bool get isAuthenticated => _authService.isAuthenticated;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) {
    final firestore = _effectiveFirestore;
    if (firestore == null) {
      throw StateError('FirebaseFirestore não foi inicializado.');
    }
    return firestore.collection('users').doc(uid);
  }

  /// Cria um código de professor único, ex: PROF-8421
  static String generateAccessCode() {
    final random = Random();
    final digits = List.generate(4, (_) => random.nextInt(10)).join();
    return 'PROF-$digits';
  }

  /// Registra um novo professor com e-mail e senha e salva seu perfil.
  Future<UserProfile> signUp({
    required String name,
    required String email,
    required String password,
    String? school,
  }) async {
    final credential = await _authService.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw const AuthException('Não foi possível obter dados do usuário criado.');
    }

    try {
      await user.updateDisplayName(name.trim());
    } catch (_) {}

    final profile = UserProfile(
      uid: user.uid,
      name: name.trim(),
      email: email.trim().toLowerCase(),
      school: school?.trim() ?? '',
      accessCode: generateAccessCode(),
      isAnonymous: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _userDoc(user.uid).set(profile.toMap(), SetOptions(merge: true));
    return profile;
  }

  /// Autentica um professor com e-mail e senha e carrega seu perfil.
  Future<UserProfile> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _authService.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw const AuthException('Credenciais inválidas.');
    }

    return await getOrCreateProfile(user);
  }

  /// Autentica como convidado (sessão anônima).
  Future<UserProfile> signInAsGuest() async {
    final credential = await _authService.signInAnonymously();
    final user = credential.user;
    if (user == null) {
      throw const AuthException('Não foi possível autenticar como convidado.');
    }

    return await getOrCreateProfile(user, isGuest: true);
  }

  /// Recupera o perfil do professor a partir do Firestore ou cria um default.
  Future<UserProfile> getOrCreateProfile(User user, {bool isGuest = false}) async {
    final docSnapshot = await _userDoc(user.uid).get();
    if (docSnapshot.exists && docSnapshot.data() != null) {
      return UserProfile.fromDocument(docSnapshot);
    }

    // Perfil inicial padrão caso o documento ainda não exista
    final initialProfile = UserProfile(
      uid: user.uid,
      name: isGuest
          ? 'Professor Convidado'
          : (user.displayName ?? user.email?.split('@').first ?? 'Professor'),
      email: user.email ?? '',
      school: '',
      accessCode: generateAccessCode(),
      isAnonymous: isGuest || user.isAnonymous,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _userDoc(user.uid).set(initialProfile.toMap(), SetOptions(merge: true));
    return initialProfile;
  }

  /// Carrega o perfil do usuário logado atualmente.
  Future<UserProfile?> getCurrentProfile() async {
    final user = _authService.currentUser;
    if (user == null) return null;
    return await getOrCreateProfile(user);
  }

  /// Atualiza os dados do perfil no Firestore.
  Future<void> updateProfile(UserProfile profile) async {
    await _userDoc(profile.uid).update(profile.toMap());
  }

  /// Envia e-mail de recuperação de senha.
  Future<void> sendPasswordReset(String email) async {
    await _authService.sendPasswordResetEmail(email);
  }

  /// Encerra a sessão atual.
  Future<void> signOut() async {
    await _authService.signOut();
  }
}
