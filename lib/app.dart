import 'package:flutter/material.dart';

import 'core/routes/app_routes.dart';
import 'core/services/firebase_service.dart';
import 'core/theme/app_theme.dart';

class AvaliaProApp extends StatelessWidget {
  const AvaliaProApp({super.key, this.firebaseInitialized = true});

  final bool firebaseInitialized;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Avalia Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: firebaseInitialized
      ? null
      : const _FirebaseInitializationErrorScreen(),
      initialRoute: firebaseInitialized ? AppRoutes.access : null,
      onGenerateRoute: firebaseInitialized ? AppRoutes.onGenerateRoute : null,
    );
  }
}

class _FirebaseInitializationErrorScreen extends StatefulWidget {
  const _FirebaseInitializationErrorScreen();

  @override
  State<_FirebaseInitializationErrorScreen> createState() =>
  _FirebaseInitializationErrorScreenState();
}

class _FirebaseInitializationErrorScreenState
extends State<_FirebaseInitializationErrorScreen> {
  bool _retrying = false;
  String? _error;

  Future<void> _retry() async {
    setState(() {
      _retrying = true;
      _error = null;
    });
    final success = await FirebaseService.initialize();
    if (!mounted) return;
    if (success) {
      runApp(const AvaliaProApp(firebaseInitialized: true));
      return;
    }
    setState(() {
      _retrying = false;
      _error = 'A inicialização falhou novamente. Confira a configuração e os logs.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_outlined, size: 48),
                const SizedBox(height: 16),
                Text('Não foi possível conectar ao Firebase', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                const Text(
                  'O aplicativo precisa inicializar o Firebase e autenticar a sessão para acessar os dados. Nenhum dado simulado será exibido como se fosse real.',
                  textAlign: TextAlign.center,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _retrying ? null : _retry,
                  child: Text(_retrying ? 'Tentando novamente...' : 'Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
