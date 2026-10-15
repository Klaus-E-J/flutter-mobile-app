import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

/// Serviço responsável pelo ciclo de vida e inicialização resiliente do Firebase e Firestore.
class FirebaseService {
  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  static FirebaseFirestore? _firestoreInstance;

  /// Retorna a instância ativa do Firestore, ou `null` se o Firebase não estiver inicializado.
  static FirebaseFirestore? get firestore {
    if (!_initialized) return null;
    return _firestoreInstance ??= FirebaseFirestore.instance;
  }

  /// Inicializa o Firebase com tratamento gracioso de falhas e fallback.
  static Future<bool> initialize() async {
    if (_initialized) return true;

    try {
      if (Firebase.apps.isNotEmpty) {
        _initialized = true;
        _firestoreInstance = FirebaseFirestore.instance;
        return true;
      }

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      _initialized = true;
      _firestoreInstance = FirebaseFirestore.instance;

      // Habilita persistência offline do Firestore quando disponível
      _firestoreInstance?.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      debugPrint('Firebase e Cloud Firestore inicializados com sucesso no projeto: ${DefaultFirebaseOptions.projectId}');
      return true;
    } catch (e) {
      debugPrint('Aviso: Falha ao inicializar Firebase nativo ($e). O app operará em modo offline/repositório local resiliente.');
      _initialized = false;
      return false;
    }
  }
}
