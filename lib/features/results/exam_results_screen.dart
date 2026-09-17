import 'package:flutter/material.dart';

import '../../core/widgets/app_card.dart';
import '../../screens/correcao/models/correcao_models.dart';
import 'student_result_screen.dart';

/// FE-10 — Resultados de uma prova.
///
/// Exibe os alunos da prova.
/// Ao clicar em um aluno, abre o resultado individual.
class ExamResultsScreen extends StatelessWidget {
  const ExamResultsScreen({
    super.key,
    required this.prova,
    required this.resultados,
    this.totalErros = 0,
  });

  final ProvaCorrecao prova;
  final List<ResultadoAluno> resultados;
  final int totalErros;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final media = resultados.isEmpty
        ? 0.0
        : resultados.fold<double>(
                0,
                (sum, resultado) => sum + resultado.percentual,
              ) /
              resultados.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados da prova'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              prova.titulo,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),

            Text(
              '${prova.turma} · ${prova.disciplina}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 20),

            AppCard(
              child: Row(
                children: [
                  Expanded(
                    child: _ResumoItem(
                      valor: '${resultados.length}',
                      titulo: 'Alunos',
                    ),
                  ),
                  Expanded(
                    child: _ResumoItem(
                      valor: '${media.toStringAsFixed(0)}%',
                      titulo: 'Média',
                    ),
                  ),
                  Expanded(
                    child: _ResumoItem(
                      valor: '${prova.totalQuestoes}',
                      titulo: 'Questões',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Alunos',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              'Selecione um aluno para visualizar o resultado individual.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 12),

            if (resultados.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'Nenhum resultado disponível.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              for (final resultado in resultados) ...[
                _AlunoResultadoCard(
                  resultado: resultado,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => StudentResultScreen(
                          prova: prova,
                          resultado: resultado,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
              ],
          ],
        ),
      ),
    );
  }
}

class _ResumoItem extends StatelessWidget {
  const _ResumoItem({
    required this.valor,
    required this.titulo,
  });

  final String valor;
  final String titulo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          valor,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          titulo,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _AlunoResultadoCard extends StatelessWidget {
  const _AlunoResultadoCard({
    required this.resultado,
    required this.onTap,
  });

  final ResultadoAluno resultado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final erros =
        resultado.totalQuestoes - resultado.acertos;

    final corNota = resultado.percentual >= 60
        ? colorScheme.primary
        : colorScheme.error;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            child: Text(
              resultado.nomeAluno.isNotEmpty
                  ? resultado.nomeAluno[0]
                  : '?',
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resultado.nomeAluno,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${resultado.acertos} acertos • $erros erros',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                resultado.nota,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: corNota,
                ),
              ),
              Text(
                '${resultado.percentual.toStringAsFixed(0)}%',
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