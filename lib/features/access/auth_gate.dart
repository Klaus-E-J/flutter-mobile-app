import 'package:flutter/material.dart';

import '../../core/navigation/app_shell.dart';
import '../../core/services/firebase_service.dart';
import 'access_screen.dart';

/// Ponto de entrada de roteamento que verifica se há uma sessão Firebase ativa.
/// Se autenticado, abre o app (AppShell); caso contrário, exibe a tela de acesso/login.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    if (FirebaseService.isInitialized && FirebaseService.currentUser != null) {
      return const AppShell();
    }
    return const AccessScreen();
  }
}
