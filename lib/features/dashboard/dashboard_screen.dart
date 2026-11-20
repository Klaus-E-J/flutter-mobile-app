import 'package:flutter/material.dart';

import '../../core/navigation/app_tabs.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/firebase_service.dart';
import '../../core/widgets/app_card.dart';
import '../access/data/auth_repository.dart';
import '../exams/exam_form_screen.dart';
import 'dashboard_view_model.dart';
import '../../core/theme/app_icons.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardViewModel _viewModel = DashboardViewModel();
  String _professorName = 'Professor';

  @override
  void initState() {
    super.initState();
    _loadProfessorName();
  }

  Future<void> _loadProfessorName() async {
    try {
      if (!FirebaseService.isInitialized) return;
      final user = FirebaseService.currentUser;
      if (user == null) return;
      if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
        if (mounted) {
          setState(() {
            _professorName = user.displayName!.trim().split(' ').first;
          });
        }
        return;
      }
      final profile = await AuthRepository().getCurrentProfile();
      if (profile != null && profile.name.trim().isNotEmpty && mounted) {
        setState(() {
          _professorName = profile.name.trim().split(' ').first;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _goTo(AppTab tab) => AppTabs.go(context, tab);

  _NextStep _nextStepFor(DashboardStats stats) {
    if (stats.classCount == 0) {
      return _NextStep(
        icon: AppIcons.classes,
        title: 'Cadastre sua primeira turma',
        description: 'Adicione os alunos manualmente ou importe uma lista.',
        actionLabel: 'Ir para Turmas',
        onPressed: () => _goTo(AppTab.classes),
      );
    }
    if (stats.examCount == 0) {
      return _NextStep(
        icon: AppIcons.exams,
        title: 'Crie sua primeira prova',
        description: 'Vincule turmas, cadastre o gabarito e imprima as folhas.',
        actionLabel: 'Criar prova',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const ExamFormScreen()),
        ),
      );
    }
    if (stats.pendingCount > 0) {
      final plural = stats.pendingCount > 1;
      return _NextStep(
        icon: AppIcons.correction,
        title: plural
            ? '${stats.pendingCount} provas aguardando correção'
            : '1 prova aguardando correção',
        description: 'Escaneie as folhas de resposta com a câmera.',
        actionLabel: 'Corrigir agora',
        onPressed: () => _goTo(AppTab.correction),
      );
    }
    return _NextStep(
      icon: AppIcons.success,
      title: 'Tudo corrigido',
      description: 'Confira o desempenho das turmas e exporte as notas.',
      actionLabel: 'Ver resultados',
      onPressed: () => _goTo(AppTab.results),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Início'),
        actions: [
          IconButton(
            icon: const Icon(AppIcons.settings),
            tooltip: 'Configurações',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.config),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            final stats = _viewModel.stats;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: [
                Text('Olá, $_professorName', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  'Veja o resumo das suas avaliações.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: stats.isLoading
                      ? const SizedBox(key: ValueKey('loading'), height: 132)
                      : _NextStepCard(
                          key: ValueKey(_nextStepFor(stats).title),
                          step: _nextStepFor(stats),
                        ),
                ),
                const SizedBox(height: 24),
                Text('Visão geral', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    mainAxisExtent: 116,
                  ),
                  children: [
                    _StatTile(
                      icon: AppIcons.classes,
                      label: 'Turmas',
                      value: stats.isLoading ? null : stats.classCount,
                      onTap: () => _goTo(AppTab.classes),
                    ),
                    _StatTile(
                      icon: AppIcons.exams,
                      label: 'Provas',
                      value: stats.isLoading ? null : stats.examCount,
                      onTap: () => _goTo(AppTab.exams),
                    ),
                    _StatTile(
                      icon: AppIcons.pending,
                      label: 'A corrigir',
                      value: stats.isLoading ? null : stats.pendingCount,
                      highlight: !stats.isLoading && stats.pendingCount > 0,
                      onTap: () => _goTo(AppTab.correction),
                    ),
                    _StatTile(
                      icon: AppIcons.results,
                      label: 'Folhas corrigidas',
                      value: stats.isLoading ? null : stats.submissionCount,
                      onTap: () => _goTo(AppTab.results),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NextStep {
  const _NextStep({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onPressed;
}

/// Destaque único do Início: a ação mais útil para o momento do professor.
class _NextStepCard extends StatelessWidget {
  const _NextStepCard({super.key, required this.step});

  final _NextStep step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      color: colorScheme.primaryContainer,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(step.icon, color: colorScheme.onPrimaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  step.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            step.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: step.onPressed,
            child: Text(step.actionLabel),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final int? value;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = highlight ? colorScheme.tertiary : colorScheme.primary;

    return MergeSemantics(
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: accent),
                const Spacer(),
                Icon(
                  AppIcons.chevron,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    value?.toString() ?? '–',
                    key: ValueKey(value),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: highlight ? accent : null,
                    ),
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
