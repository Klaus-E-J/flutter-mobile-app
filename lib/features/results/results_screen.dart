import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../screens/correcao/models/correcao_models.dart';
import '../correction/data/submission_repository.dart';
import 'exam_results_screen.dart';

/// Central de Resultados integrada com o Cloud Firestore.
///
/// Lista as correções reais salvas em `users/{uid}/submissions`.
/// Ao selecionar uma prova, abre a lista de alunos daquela prova.
class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  static final SubmissionRepository _submissionRepository =
      SubmissionRepository();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados'),
      ),
      body: SafeArea(
        child: StreamBuilder<List<ExamCorrectionSummary>>(
          stream: _submissionRepository.watchExamSummaries(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Erro ao carregar resultados: ${snapshot.error}'),
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final summaries = snapshot.data!;
            if (summaries.isEmpty) {
              return AppEmptyState(
                icon: Icons.assignment_outlined,
                title: 'Nenhum resultado ainda',
                description:
                    'Os resultados aparecerão aqui após você concluir uma correção.',
                action: FilledButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.correction),
                  icon: const Icon(Icons.adjust_outlined),
                  label: const Text('Iniciar correção'),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Correções realizadas',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${summaries.length} avaliação(ões) corrigida(s)',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
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
                for (final summary in summaries) ...[
                  _SummaryCard(
                    summary: summary,
                    onTap: () {
                      final prova = ProvaCorrecao(
                        id: summary.examId,
                        titulo: summary.examTitle,
                        turma: summary.className,
                        disciplina: 'Avaliação',
                        totalQuestoes: summary.totalQuestions,
                        totalAlunos: summary.studentCount,
                        classId: summary.classId,
                      );

                      final resultados = summary.submissions.map((sub) {
                        return ResultadoAluno(
                          studentId: sub.studentId,
                          nomeAluno: sub.studentName,
                          acertos: sub.score,
                          totalQuestoes: sub.totalQuestions,
                          answers: sub.answers,
                        );
                      }).toList();

                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => ExamResultsScreen(
                            prova: prova,
                            resultados: resultados,
                            totalErros: 0,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

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
          Icon(
            icon,
            size: 20,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.summary,
    required this.onTap,
  });

  final ExamCorrectionSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final media = summary.averageScore;
    final corMedia = media >= 60 ? colorScheme.primary : colorScheme.error;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary.examTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  summary.className,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${summary.studentCount} aluno(s) · '
                  '${summary.totalQuestions} questões',
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
          Icon(
            Icons.chevron_right,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
