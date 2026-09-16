import 'package:flutter/material.dart';

import '../../screens/correcao/models/correcao_models.dart';

/// Resultado mockado de uma questão.
///
/// A FE-10 apenas exibe estes dados.
/// Não realiza leitura, comparação ou correção real.
class QuestionResultMock {
  const QuestionResultMock({
    required this.number,
    required this.marked,
    required this.correct,
    required this.isCorrect,
  });

  final int number;
  final String marked;
  final String correct;
  final bool isCorrect;
}

/// FE-10 — Resultado individual do aluno.
///
/// Mostra:
/// - aluno;
/// - prova;
/// - nota;
/// - acertos;
/// - erros;
/// - alternativa marcada;
/// - alternativa correta.
///
/// Todos os dados são mockados.
class StudentResultScreen extends StatelessWidget {
  const StudentResultScreen({
    super.key,
    required this.prova,
    required this.resultado,
  });

  final ProvaCorrecao prova;
  final ResultadoAluno resultado;

  List<QuestionResultMock> _gerarQuestoesMock() {
    const alternativas = [
      'A',
      'B',
      'C',
      'D',
      'E',
    ];

    return List<QuestionResultMock>.generate(
      resultado.totalQuestoes,
      (index) {
        final alternativaCorreta =
            alternativas[index % alternativas.length];

        // Apenas montagem de dados mockados para a N1.
        // Não representa lógica real de correção.
        final acertou = index < resultado.acertos;

        final alternativaMarcada = acertou
            ? alternativaCorreta
            : alternativas[
                (index + 1) % alternativas.length
              ];

        return QuestionResultMock(
          number: index + 1,
          marked: alternativaMarcada,
          correct: alternativaCorreta,
          isCorrect: acertou,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final erros =
        resultado.totalQuestoes - resultado.acertos;

    final questoes = _gerarQuestoesMock();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado do aluno'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            28,
          ),
          children: [
            Text(
              'Correção individual',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 14),

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
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    resultado.nota,
                    style:
                        theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    '${resultado.acertos} acertos de '
                    '${resultado.totalQuestoes} questões',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),

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
                          titulo: 'Erros',
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
              'Confira a alternativa marcada pelo aluno '
              'e a alternativa correta.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 12),

            for (final questao in questoes) ...[
              _QuestaoResultadoCard(
                questao: questao,
              ),
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
            crossAxisAlignment:
                CrossAxisAlignment.start,
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
                  color:
                      theme.colorScheme.onSurfaceVariant,
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

  final QuestionResultMock questao;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final resultColor = questao.isCorrect
        ? Colors.green.shade700
        : theme.colorScheme.error;

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
              'Questão ${questao.number}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          Flexible(
            child: Text(
              'Marcada: ${questao.marked} • '
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