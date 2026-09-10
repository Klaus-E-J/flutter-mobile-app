import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Início'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Configurações',
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.config);
            },
          ),
        ],
      ),

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Olá, Professor',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              'Visão geral',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 16),

            const Row(
              children: [
                Expanded(
                  child: _StatisticCard(
                    value: '12',
                    label: 'Provas',
                    icon: Icons.description_outlined,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _StatisticCard(
                    value: '4',
                    label: 'Turmas',
                    icon: Icons.groups_outlined,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _StatisticCard(
                    value: '8',
                    label: 'Pendentes',
                    icon: Icons.pending_outlined,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            AppButton(
              label: 'Nova prova',
              icon: Icons.add,
              expanded: true,
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.exams);
              },
            ),

            const SizedBox(height: 24),

            Text(
              'Acesso rápido',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            _QuickAccessCard(
              icon: Icons.groups_outlined,
              title: 'Turmas',
              description: 'Gerencie alunos e turmas',
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.classes);
              },
            ),

            const SizedBox(height: 10),

            _QuickAccessCard(
              icon: Icons.description_outlined,
              title: 'Provas',
              description: 'Crie e configure avaliações',
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.exams);
              },
            ),

            const SizedBox(height: 10),

            _QuickAccessCard(
              icon: Icons.adjust_outlined,
              title: 'Corrigir',
              description: 'Leia QR, gabarito e provas',
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.correction);
              },
            ),

            const SizedBox(height: 10),

            _QuickAccessCard(
              icon: Icons.assignment_outlined,
              title: 'Resultados',
              description: 'Consultar provas corrigidas',
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.results);
              },
            ),

            const SizedBox(height: 10),

            _QuickAccessCard(
              icon: Icons.bar_chart_outlined,
              title: 'Estatísticas',
              description: 'Analisar desempenho',
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.statistics);
              },
            ),

            const SizedBox(height: 10),

            _QuickAccessCard(
              icon: Icons.upload_outlined,
              title: 'Exportar',
              description: 'Exportar resultados',
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.export);
              },
            ),
          ],
        ),
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              // Tela atual
              break;

            case 1:
              Navigator.pushNamed(context, AppRoutes.classes);
              break;

            case 2:
              Navigator.pushNamed(context, AppRoutes.exams);
              break;

            case 3:
              Navigator.pushNamed(context, AppRoutes.correction);
              break;

            case 4:
              _showMaisModal(context);
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Turmas',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: 'Provas',
          ),
          NavigationDestination(
            icon: Icon(Icons.adjust_outlined),
            selectedIcon: Icon(Icons.adjust),
            label: 'Corrigir',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz),
            label: 'Mais',
          ),
        ],
      ),
    );
  }
}

/// Exibe um modal bottom sheet com as ações secundárias do app.
void _showMaisModal(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mais opções',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _ModalActionTile(
                icon: Icons.assignment_outlined,
                label: 'Resultados',
                description: 'Consultar correções realizadas',
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, AppRoutes.results);
                },
              ),
              _ModalActionTile(
                icon: Icons.bar_chart_outlined,
                label: 'Estatísticas',
                description: 'Analisar desempenho das turmas',
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, AppRoutes.statistics);
                },
              ),
              _ModalActionTile(
                icon: Icons.upload_outlined,
                label: 'Exportar',
                description: 'Exportar resultados e dados',
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, AppRoutes.export);
                },
              ),
              _ModalActionTile(
                icon: Icons.settings_outlined,
                label: 'Configurações',
                description: 'Código de acesso e preferências',
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, AppRoutes.config);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _ModalActionTile extends StatelessWidget {
  const _ModalActionTile({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: colorScheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: colorScheme.outlineVariant,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatisticCard extends StatelessWidget {
  const _StatisticCard({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  const _QuickAccessCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            size: 18,
            color: colorScheme.outlineVariant,
          ),
        ],
      ),
    );
  }
}