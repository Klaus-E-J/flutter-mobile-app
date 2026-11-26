import 'package:flutter/material.dart';

import '../routes/app_routes.dart';

/// Abas principais do app, na ordem em que aparecem na barra inferior.
enum AppTab { home, classes, exams, correction, results }

/// Implementado pelo shell de navegação para receber pedidos de troca de aba.
abstract interface class AppTabNavigator {
  void selectTab(AppTab tab);
}

/// Ponto único para trocar de aba a partir de qualquer tela.
///
/// Telas empilhadas por cima do shell (ex.: o fim da correção) não estão
/// abaixo dele na árvore de widgets, por isso o acesso é estático.
abstract final class AppTabs {
  static final List<AppTabNavigator> _navigators = [];

  /// Aba visível no momento. Útil para recarregar dados ao voltar para uma aba.
  static final ValueNotifier<AppTab> current = ValueNotifier(AppTab.home);

  static void attach(AppTabNavigator navigator) => _navigators.add(navigator);

  static void detach(AppTabNavigator navigator) =>
      _navigators.remove(navigator);

  /// Volta até o shell (se houver telas por cima) e mostra a aba [tab].
  static void go(BuildContext context, AppTab tab) {
    Navigator.of(context).popUntil(
      (route) => route.isFirst || route.settings.name == AppRoutes.dashboard,
    );
    if (_navigators.isNotEmpty) _navigators.last.selectTab(tab);
  }
}
