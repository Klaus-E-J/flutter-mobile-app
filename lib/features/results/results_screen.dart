import 'package:flutter/material.dart';

import '../../core/navigation/app_tabs.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_error_state.dart';
import '../../core/widgets/app_loading.dart';
import '../../screens/correcao/models/correcao_models.dart';
import '../correction/data/submission_repository.dart';
import 'exam_results_screen.dart';
import '../../core/theme/app_icons.dart';
import '../../core/widgets/app_delete_button.dart';
import '../../core/widgets/app_snack_bar.dart';
import '../../core/widgets/app_dialog.dart';

/// Central de Resultados integrada com o Cloud Firestore.
///
/// Lista as correções reais salvas em `users/{uid}/submissions`.
/// Ao selecionar uma prova, abre a lista de alunos daquela prova.
class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  static final SubmissionRepository _submissionRepository =
      SubmissionRepository();

  Future<void> _confirmDeleteSummary(
    BuildContext context,
    ExamCorrectionSummary summary,
  ) async {
    final confirmed = await AppDialog.confirm(
      context: context,
      title: 'Excluir resultados?',
      message: 'Tem certeza que deseja excluir todas as ${summary.studentCount} correções de "${summary.examTitle}" (${summary.className})?',
      confirmLabel: 'Excluir',
      destructive: true,
    );
    if (!context.mounted || confirmed != true) return;

    try {
      await _submissionRepository.deleteSubmissionsByExam(
        summary.examId,
        classId: summary.classId.isNotEmpty ? summary.classId : null,
      );
      if (!context.mounted) return;
      AppSnackBar.success(context, 'Resultados excluídos com sucesso.');
    } catch (error) {
      if (!context.mounted) return;
      AppSnackBar.error(context, 'Não foi possível excluir os resultados: $error');
    }
  }

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
              return AppErrorState(
                title: 'Não foi possível carregar os resultados',
                description: '${snapshot.error}',
              );
            }

            if (!snapshot.hasData) return const AppLoading();

            final summaries = snapshot.data!;
            if (summaries.isEmpty) {
              return AppEmptyState(
                icon: AppIcons.results,
                title: 'Nenhum resultado ainda',
                description:
                    'Os resultados aparecem aqui assim que você concluir uma correção.',
                action: FilledButton.icon(
                  onPressed: () => AppTabs.go(context, AppTab.correction),
                  icon: const Icon(AppIcons.correction),
                  label: const Text('Ir para Corrigir'),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: [
                Text(
                  summaries.length == 1
                      ? '1 avaliação corrigida'
                      : '${summaries.length} avaliações corrigidas',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _AtalhoCard(
                        icon: AppIcons.statistics,
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
                        icon: AppIcons.export,
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
                Text('Histórico', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                for (final summary in summaries) ...[
                  _SummaryCard(
                    summary: summary,
                    onDelete: () => _confirmDeleteSummary(context, summary),
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
                          submissionId: sub.id,
                          studentId: sub.studentId,
                          nomeAluno: sub.studentName,
                          acertos: sub.score,
                          totalQuestoes: sub.totalQuestions,
                          variantId: sub.variantId,
                          variantCode: sub.variantCode,
                          emBranco: sub.blankCount,
                          invalidas: sub.invalidCount,
                          notaFinal10: sub.finalGrade,
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
            style: Theme.of(context).textTheme.titleSmall,
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
    required this.onDelete,
  });

  final ExamCorrectionSummary summary;
  final VoidCallback onTap;
  final VoidCallback onDelete;

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
                  style: theme.textTheme.titleMedium,
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
          AppDeleteButton(tooltip: 'Excluir resultados desta avaliação', onPressed: onDelete),
          Icon(
            AppIcons.chevron,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
