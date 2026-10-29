import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

/// Inicializa Firebase e fornece acesso aos serviços de Firestore e Auth.
///
/// Os documentos de negócio devem ficar sob `users/{uid}/...` para que as regras
/// do Firestore possam isolar os dados de cada usuário autenticado.
class FirebaseService {
  FirebaseService._();

  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  static FirebaseFirestore? _firestoreInstance;
  static FirebaseAuth? _authInstance;
  static bool _firestoreConfigured = false;

  static FirebaseFirestore get firestore {
    if (!_initialized || _firestoreInstance == null) {
      throw StateError('Firebase ainda não foi inicializado.');
    }
    return _firestoreInstance!;
  }

  static FirebaseAuth get auth {
    if (!_initialized || _authInstance == null) {
      throw StateError('Firebase ainda não foi inicializado.');
    }
    return _authInstance!;
  }

  static User? get currentUser => _authInstance?.currentUser;

  static String get uid {
    final userId = currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      throw StateError('Não há uma sessão Firebase autenticada.');
    }
    return userId;
  }

  /// Coleção raiz dos dados pertencentes ao usuário autenticado.
  static CollectionReference<Map<String, dynamic>> userCollection(
    String collection,
  ) {
    if (collection.trim().isEmpty || collection.contains('/')) {
      throw ArgumentError.value(collection, 'collection', 'Nome inválido.');
    }
    return firestore.collection('users').doc(uid).collection(collection);
  }

  /// Inicializa Firebase e prepara as instâncias do Firestore e FirebaseAuth.
  ///
  /// Retorna `false` em caso de falha, registrando o erro nos logs.
  static Future<bool> initialize() async {
    if (_initialized) return true;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      _firestoreInstance = FirebaseFirestore.instance;
      _authInstance = FirebaseAuth.instance;

      // Configurar antes de iniciar consultas ao Firestore. Em uma tentativa
      // de autenticação posterior, não reaplicar Settings à mesma instância.
      if (!_firestoreConfigured) {
        _firestoreInstance!.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
        _firestoreConfigured = true;
      }

      _initialized = true;
      final currentUid = _authInstance!.currentUser?.uid;
      if (currentUid != null) {
        debugPrint(
          'Firebase inicializado com sessão autenticada ativa: $currentUid',
        );
      } else {
        debugPrint(
          'Firebase inicializado sem sessão ativa. Redirecionando para login.',
        );
      }
      return true;
    } on FirebaseAuthException catch (error, stackTrace) {
      _initialized = false;
      debugPrint('Falha na autenticação Firebase: ${error.code}: ${error.message}');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    } on FirebaseException catch (error, stackTrace) {
      _initialized = false;
      debugPrint('Falha Firebase (${error.plugin}): ${error.code}: ${error.message}');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    } catch (error, stackTrace) {
      _initialized = false;
      debugPrint('Falha ao inicializar Firebase: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }
}
