import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Avalia Pro',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Configurações',
            onPressed: () {
              // Configurações será implementada posteriormente.
            },
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 1100,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _DashboardHeader(),
                      const SizedBox(height: 32),

                      _SectionTitle(
                        title: 'Acesso rápido',
                      ),

                      const SizedBox(height: 16),

                      GridView.count(
                        crossAxisCount: isWide ? 3 : 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: isWide ? 1.7 : 1.4,
                        children: [
                          _DashboardCard(
                            icon: Icons.groups_outlined,
                            title: 'Turmas',
                            description: 'Gerenciar turmas e alunos',
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.classes,
                              );
                            },
                          ),
                          _DashboardCard(
                            icon: Icons.assignment_outlined,
                            title: 'Provas',
                            description: 'Criar e gerenciar provas',
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.exams,
                              );
                            },
                          ),
                          _DashboardCard(
                            icon: Icons.document_scanner_outlined,
                            title: 'Iniciar correção',
                            description: 'Ler QR Code e corrigir provas',
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.correction,
                              );
                            },
                          ),
                          _DashboardCard(
                            icon: Icons.assessment_outlined,
                            title: 'Resultados',
                            description: 'Consultar provas corrigidas',
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.results,
                              );
                            },
                          ),
                          _DashboardCard(
                            icon: Icons.bar_chart_outlined,
                            title: 'Estatísticas',
                            description: 'Analisar desempenho',
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.statistics,
                              );
                            },
                          ),
                          _DashboardCard(
                            icon: Icons.file_download_outlined,
                            title: 'Exportar',
                            description: 'Exportar resultados',
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.export,
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      _SectionTitle(
                        title: 'Fluxo de correção',
                      ),

                      const SizedBox(height: 16),

                      const _CorrectionFlowCard(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Olá, professor',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Gerencie suas turmas, provas e correções.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context)
            .colorScheme
            .onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
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

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 28,
                color: colorScheme.primary,
              ),
              const Spacer(),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CorrectionFlowCard extends StatelessWidget {
  const _CorrectionFlowCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              Icons.document_scanner_outlined,
              size: 32,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Corrigir uma prova',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Leia o QR Code, selecione o gabarito e '
                  'inicie a leitura das folhas de resposta.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            FilledButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.correction,
                );
              },
              child: const Text('Iniciar'),
            ),
          ],
        ),
      ),
    );
  }
}
