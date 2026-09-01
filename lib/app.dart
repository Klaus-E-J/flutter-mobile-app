import 'package:flutter/material.dart';

import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'screens/correcao/selecao_prova_screen.dart'; // TODO: remover após teste

class AvaliaProApp extends StatelessWidget {
  const AvaliaProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Avalia Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      // TODO: reverter após teste
      // initialRoute: AppRoutes.access,
      // onGenerateRoute: AppRoutes.onGenerateRoute,
      home: const SelecaoProvaScreen(),
    );
  }
}
