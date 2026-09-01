import 'package:flutter/material.dart';

import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';

class AvaliaProApp extends StatelessWidget {
  const AvaliaProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Avalia Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialRoute: AppRoutes.access,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
