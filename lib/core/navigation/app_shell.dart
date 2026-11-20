import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../features/classes/classes_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/exams/exams_screen.dart';
import '../../features/results/results_screen.dart';
import '../../screens/correcao/selecao_prova_screen.dart';
import 'app_tabs.dart';
import '../theme/app_icons.dart';

/// Estrutura principal do app: uma única barra de navegação inferior e as
/// abas mantidas vivas (estado e rolagem preservados ao alternar).
class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initialTab = AppTab.home, this.tabBuilder});

  final AppTab initialTab;

  /// Permite trocar o conteúdo das abas em testes (as telas reais usam Firebase).
  @visibleForTesting
  final Widget Function(AppTab tab)? tabBuilder;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with SingleTickerProviderStateMixin
    implements AppTabNavigator {
  late AppTab _tab = widget.initialTab;

  /// Abas só são construídas na primeira visita, evitando carregar tudo no início.
  late final Set<AppTab> _visited = {widget.initialTab};

  late final AnimationController _transition = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    value: 1,
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _transition,
    curve: Curves.easeOutCubic,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.012),
    end: Offset.zero,
  ).animate(_fade);

  @override
  void initState() {
    super.initState();
    AppTabs.attach(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppTabs.current.value = _tab;
    });
  }

  @override
  void dispose() {
    AppTabs.detach(this);
    _transition.dispose();
    super.dispose();
  }

  @override
  void selectTab(AppTab tab) {
    if (!mounted || tab == _tab) return;
    setState(() {
      _tab = tab;
      _visited.add(tab);
    });
    AppTabs.current.value = tab;
    if (MediaQuery.disableAnimationsOf(context)) {
      _transition.value = 1;
    } else {
      _transition.forward(from: 0);
    }
  }

  Widget _buildTab(AppTab tab) {
    final custom = widget.tabBuilder;
    if (custom != null) return custom(tab);
    return switch (tab) {
      AppTab.home => const DashboardScreen(),
      AppTab.classes => const ClassesScreen(),
      AppTab.exams => const ExamsScreen(),
      AppTab.correction => const SelecaoProvaScreen(),
      AppTab.results => const ResultsScreen(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // O "voltar" do sistema leva ao Início antes de sair do app.
      canPop: _tab == AppTab.home,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) selectTab(AppTab.home);
      },
      child: Column(
        children: [
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeBottom: true,
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      for (final tab in AppTab.values)
                        if (_visited.contains(tab))
                          Offstage(
                            key: ValueKey(tab),
                            offstage: tab != _tab,
                            child: TickerMode(
                              enabled: tab == _tab,
                              child: _buildTab(tab),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          NavigationBar(
            selectedIndex: _tab.index,
            onDestinationSelected: (index) {
              HapticFeedback.selectionClick();
              selectTab(AppTab.values[index]);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(AppIcons.home),
                selectedIcon: Icon(AppIcons.homeSelected),
                label: 'Início',
              ),
              NavigationDestination(
                icon: Icon(AppIcons.classes),
                selectedIcon: Icon(AppIcons.classesSelected),
                label: 'Turmas',
              ),
              NavigationDestination(
                icon: Icon(AppIcons.exams),
                selectedIcon: Icon(AppIcons.examsSelected),
                label: 'Provas',
              ),
              NavigationDestination(
                icon: Icon(AppIcons.correction),
                selectedIcon: Icon(AppIcons.correctionSelected),
                label: 'Corrigir',
              ),
              NavigationDestination(
                icon: Icon(AppIcons.results),
                selectedIcon: Icon(AppIcons.resultsSelected),
                label: 'Resultados',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
