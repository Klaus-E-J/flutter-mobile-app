import 'package:flutter/material.dart';

import '../../screens/correcao/models/correcao_models.dart';
import '../correction/data/submission_repository.dart';

/// Resultado individual detalhado do aluno (N3-05 / N3-10).
///
/// Exibe os dados reais da submissão corrigida pelo motor OMR:
/// - Aluno, turma, prova e variante (Caderno);
/// - Nota final (0-10), percentual, acertos, erros, em branco e marcações inválidas;
/// - Detalhamento questão a questão confrontando alternativa marcada e gabarito da variante.
class StudentResultScreen extends StatelessWidget {
  const StudentResultScreen({
    super.key,
    required this.prova,
    required this.resultado,
  });

  final ProvaCorrecao prova;
  final ResultadoAluno resultado;

  List<SubmissionQuestionAnswer> _obterQuestoes() {
    return resultado.answers ?? const <SubmissionQuestionAnswer>[];
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final submissionId = resultado.submissionId;
    if (submissionId == null || submissionId.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir correção?'),
        content: Text(
          'Tem certeza que deseja excluir o resultado de "${resultado.nomeAluno}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (!context.mounted || confirmed != true) return;

    try {
      await SubmissionRepository().deleteSubmission(submissionId);
      if (!context.mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível excluir a correção: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final erros = resultado.totalQuestoes - resultado.acertos;
    final questoes = _obterQuestoes();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado do aluno'),
        actions: [
          if (resultado.submissionId != null &&
              resultado.submissionId!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Excluir resultado do aluno',
              onPressed: () => _confirmDelete(context),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Text(
              'Correção individual • Variante ${resultado.variantCode}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              resultado.nomeAluno,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${prova.turma} • ${prova.titulo}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outlineVariant,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Nota ${resultado.nota10.toStringAsFixed(1)}',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Chip(
                        label: Text('${resultado.percentual.toStringAsFixed(0)}%'),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${resultado.acertos} acertos de ${resultado.totalQuestoes} questões (${resultado.nota})',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (resultado.emBranco > 0 || resultado.invalidas > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${resultado.emBranco} em branco • ${resultado.invalidas} inválida(s)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _ContadorResultado(
                          icon: Icons.check_circle_outline,
                          titulo: 'Acertos',
                          valor: '${resultado.acertos}',
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ContadorResultado(
                          icon: Icons.cancel_outlined,
                          titulo: 'Erros / Branco',
                          valor: '$erros',
                          color: colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Questões',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Confira a alternativa reconhecida na folha OMR e o gabarito da variante.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            if (questoes.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Detalhamento por questão não disponível para este registro.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              for (final questao in questoes) ...[
                _QuestaoResultadoCard(questao: questao),
                const SizedBox(height: 8),
              ],
          ],
        ),
      ),
    );
  }
}

class _ContadorResultado extends StatelessWidget {
  const _ContadorResultado({
    required this.icon,
    required this.titulo,
    required this.valor,
    required this.color,
  });

  final IconData icon;
  final String titulo;
  final String valor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                valor,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                titulo,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuestaoResultadoCard extends StatelessWidget {
  const _QuestaoResultadoCard({
    required this.questao,
  });

  final SubmissionQuestionAnswer questao;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final resultColor = questao.isCorrect
        ? Colors.green.shade700
        : theme.colorScheme.error;

    final origNum = questao.originalQuestionNumber;
    final hasDifferentOriginal =
        origNum != null && origNum != questao.questionNumber;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Icon(
            questao.isCorrect
                ? Icons.check_circle_outline
                : Icons.cancel_outlined,
            size: 20,
            color: resultColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hasDifferentOriginal
                  ? 'Questão ${questao.questionNumber} (Original Q$origNum)'
                  : 'Questão ${questao.questionNumber}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Flexible(
            child: Text(
              'Marcada: ${questao.marked.isEmpty ? "EM BRANCO" : questao.marked} • '
              'Correta: ${questao.correct}',
              textAlign: TextAlign.end,
              style: theme.textTheme.labelMedium?.copyWith(
                color: resultColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}