import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../screens/correcao/models/correcao_models.dart';
import '../../screens/correcao/resultado_correcao_screen.dart';

/// Central de Resultados (FE-10).
///
/// Lista as correções realizadas (dados mockados).
/// Cada item abre o detalhamento por aluno.
/// Oferece atalhos para Estatísticas e Exportação.
class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  static final List<_ResultadoResumo> _resultados = [
    _ResultadoResumo(
      prova: ProvaCorrecao(
        id: '1',
        titulo: 'Prova 1 — Matemática',
        turma: '9º Ano A',
        disciplina: 'Matemática',
        totalQuestoes: 10,
        totalAlunos: 28,
        dataCriacao: DateTime(2026, 8, 20),
      ),
      resultados: gerarResultadosMock(20, 10),
      totalErros: 1,
    ),
    _ResultadoResumo(
      prova: ProvaCorrecao(
        id: '2',
        titulo: 'Português — Unidade 2',
        turma: '8º Ano B',
        disciplina: 'Português',
        totalQuestoes: 15,
        totalAlunos: 24,
        dataCriacao: DateTime(2026, 8, 25),
      ),
      resultados: gerarResultadosMock(18, 15),
      totalErros: 0,
    ),
    _ResultadoResumo(
      prova: ProvaCorrecao(
        id: '3',
        titulo: 'Ciências — Bimestre 1',
        turma: 'Ensino Médio — 1A',
        disciplina: 'Ciências',
        totalQuestoes: 25,
        totalAlunos: 31,
        dataCriacao: DateTime(2026, 8, 30),
      ),
      resultados: gerarResultadosMock(15, 25),
      totalErros: 2,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados'),
      ),
      body: SafeArea(
        child: _resultados.isEmpty
            ? AppEmptyState(
                icon: Icons.assignment_outlined,
                title: 'Nenhum resultado ainda',
                description:
                    'Os resultados aparecerão aqui após você concluir '
                    'uma correção.',
                action: FilledButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.correction),
                  icon: const Icon(Icons.adjust_outlined),
                  label: const Text('Iniciar correção'),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Cabeçalho
                  Text(
                    'Correções realizadas',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_resultados.length} prova(s) corrigida(s)',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),

                  const SizedBox(height: 16),

                  // Atalhos rápidos
                  Row(
                    children: [
                      Expanded(
                        child: _AtalhoCard(
                          icon: Icons.bar_chart_outlined,
                          label: 'Estatísticas',
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.statistics,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _AtalhoCard(
                          icon: Icons.upload_outlined,
                          label: 'Exportar',
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.export,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Histórico',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Lista de resultados
                  for (final item in _resultados) ...[
                    _ResultadoCard(
                      item: item,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ResultadoCorrecaoScreen(
                            prova: item.prova,
                            resultados: item.resultados,
                            totalErros: item.totalErros,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
      ),
    );
  }
}

/// Card de atalho rápido (Estatísticas / Exportar).
class _AtalhoCard extends StatelessWidget {
  const _AtalhoCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Card de um resultado na lista histórica.
class _ResultadoCard extends StatelessWidget {
  const _ResultadoCard({required this.item, required this.onTap});

  final _ResultadoResumo item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final media = item.resultados.isEmpty
        ? 0.0
        : item.resultados.fold<double>(
                0, (sum, r) => sum + r.percentual) /
            item.resultados.length;

    final corMedia =
        media >= 60 ? colorScheme.primary : colorScheme.error;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.prova.titulo,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.prova.turma} · ${item.prova.disciplina}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.resultados.length} aluno(s) · '
                  '${item.prova.totalQuestoes} questões',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${media.toStringAsFixed(0)}%',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: corMedia,
                ),
              ),
              Text(
                'média',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

/// Modelo local para o resumo de um resultado na lista.
class _ResultadoResumo {
  const _ResultadoResumo({
    required this.prova,
    required this.resultados,
    required this.totalErros,
  });

  final ProvaCorrecao prova;
  final List<ResultadoAluno> resultados;
  final int totalErros;
}
