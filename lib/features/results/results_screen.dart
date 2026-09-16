import 'package:flutter/material.dart';

/// Dados prontos de uma questão.
/// A FE-10 apenas exibe esses valores.
class QuestionResultData {
  const QuestionResultData({
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
/// Somente Front-End.
/// Não calcula nota e não realiza correção.
class ResultsScreen extends StatelessWidget {
  const ResultsScreen({
    super.key,
    this.studentName = 'Ana Silva',
    this.className = '9º Ano A',
    this.examTitle = 'Avaliação Matemática',
    this.score = '8,5 / 10',
    this.hits = 17,
    this.errors = 3,
    this.totalQuestions = 20,
    this.questions = const <QuestionResultData>[],
  });

  final String studentName;
  final String className;
  final String examTitle;

  final String score;
  final int hits;
  final int errors;
  final int totalQuestions;

  final List<QuestionResultData> questions;

  static const List<QuestionResultData> _defaultQuestions = [
    QuestionResultData(number: 1, marked: 'B', correct: 'B', isCorrect: true),
    QuestionResultData(number: 2, marked: 'C', correct: 'B', isCorrect: false),
    QuestionResultData(number: 3, marked: 'B', correct: 'B', isCorrect: true),
    QuestionResultData(number: 4, marked: 'B', correct: 'B', isCorrect: true),
    QuestionResultData(number: 5, marked: 'B', correct: 'B', isCorrect: true),
    QuestionResultData(number: 6, marked: 'D', correct: 'D', isCorrect: true),
    QuestionResultData(number: 7, marked: 'A', correct: 'A', isCorrect: true),
    QuestionResultData(number: 8, marked: 'C', correct: 'C', isCorrect: true),
    QuestionResultData(number: 9, marked: 'E', correct: 'E', isCorrect: true),
    QuestionResultData(number: 10, marked: 'A', correct: 'A', isCorrect: true),
    QuestionResultData(number: 11, marked: 'B', correct: 'B', isCorrect: true),
    QuestionResultData(number: 12, marked: 'A', correct: 'C', isCorrect: false),
    QuestionResultData(number: 13, marked: 'D', correct: 'D', isCorrect: true),
    QuestionResultData(number: 14, marked: 'E', correct: 'E', isCorrect: true),
    QuestionResultData(number: 15, marked: 'C', correct: 'C', isCorrect: true),
    QuestionResultData(number: 16, marked: 'B', correct: 'B', isCorrect: true),
    QuestionResultData(number: 17, marked: 'A', correct: 'A', isCorrect: true),
    QuestionResultData(number: 18, marked: 'D', correct: 'B', isCorrect: false),
    QuestionResultData(number: 19, marked: 'C', correct: 'C', isCorrect: true),
    QuestionResultData(number: 20, marked: 'E', correct: 'E', isCorrect: true),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final displayedQuestions =
        questions.isEmpty ? _defaultQuestions : questions;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Resultados',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Text(
              'Correção individual',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),

            Text(
              studentName,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),

            Text(
              '$className • $examTitle',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 18),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    score,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),

                  Text(
                    '$hits acertos de $totalQuestions questões',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _ResumoItem(
                          titulo: 'Acertos',
                          valor: '$hits',
                          icon: Icons.check_circle_outline,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ResumoItem(
                          titulo: 'Erros',
                          valor: '$errors',
                          icon: Icons.cancel_outlined,
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
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),

            for (final question in displayedQuestions) ...[
              _QuestionCard(question: question),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResumoItem extends StatelessWidget {
  const _ResumoItem({
    required this.titulo,
    required this.valor,
    required this.icon,
    required this.color,
  });

  final String titulo;
  final String valor;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                valor,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
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

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.question});

  final QuestionResultData question;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color =
        question.isCorrect ? Colors.green.shade700 : colorScheme.error;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(
            question.isCorrect
                ? Icons.check_circle_outline
                : Icons.cancel_outlined,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Questão ${question.number}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            'Marcada: ${question.marked} • Correta: ${question.correct}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
