
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
        title: const Text(
          'Início',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _StatisticCard(
                    value: '4',
                    label: 'Turmas',
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _StatisticCard(
                    value: '8',
                    label: 'Pendentes',
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
              title: 'Turmas',
              description: 'Gerencie alunos e turmas',
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.classes);
              },
            ),

            const SizedBox(height: 10),

            _QuickAccessCard(
              title: 'Provas',
              description: 'Crie e configure avaliações',
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.exams);
              },
            ),

            const SizedBox(height: 10),

            _QuickAccessCard(
              title: 'Corrigir',
              description: 'Leia QR, gabarito e provas',
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.correction);
              },
            ),

            const SizedBox(height: 10),

            _QuickAccessCard(
              title: 'Resultados',
              description: 'Consultar provas corrigidas',
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.results);
              },
            ),

            const SizedBox(height: 10),

            _QuickAccessCard(
              title: 'Estatísticas',
              description: 'Analisar desempenho',
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.statistics);
              },
            ),

            const SizedBox(height: 10),

            _QuickAccessCard(
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
              Navigator.pushNamed(
                context,
                AppRoutes.classes,
              );
              break;

            case 2:
              Navigator.pushNamed(
                context,
                AppRoutes.exams,
              );
              break;

            case 3:
              Navigator.pushNamed(
                context,
                AppRoutes.correction,
              );
              break;

            case 4:
            // Mais
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
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.groups_outlined),
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

class _StatisticCard extends StatelessWidget {
  const _StatisticCard({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
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
    required this.title,
    required this.description,
    required this.onTap,
  });

  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}