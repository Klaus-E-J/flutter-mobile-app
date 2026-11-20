import 'package:flutter/material.dart';

import '../../features/access/access_screen.dart';
import '../../features/access/auth_gate.dart';
import '../../features/config/config_screen.dart';
import '../../features/export/export_screen.dart';
import '../../features/statistics/statistics_screen.dart';
import '../../features/ui_preview/ui_preview_screen.dart';
import '../navigation/app_shell.dart';
import '../navigation/app_tabs.dart';

abstract final class AppRoutes {
  static const root = '/';
  static const access = '/access';
  static const dashboard = '/dashboard';
  static const classes = '/classes';
  static const exams = '/exams';
  static const correction = '/correction';
  static const results = '/results';
  static const statistics = '/statistics';
  static const export = '/export';
  static const config = '/config';
  static const uiPreview = '/ui-preview';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final Widget page = switch (settings.name) {
      root => const AuthGate(),
      access => const AccessScreen(),
      // As abas principais vivem dentro do AppShell. Para trocar de aba a
      // partir de uma tela, use AppTabs.go(context, tab) em vez destas rotas.
      dashboard => const AppShell(),
      classes => const AppShell(initialTab: AppTab.classes),
      exams => const AppShell(initialTab: AppTab.exams),
      correction => const AppShell(initialTab: AppTab.correction),
      results => const AppShell(initialTab: AppTab.results),
      statistics => const StatisticsScreen(),
      export => const ExportScreen(),
      config => const ConfigScreen(),
      uiPreview => const UiPreviewScreen(),
      _ => const Scaffold(body: Center(child: Text('Página não encontrada'))),
    };
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }
}
