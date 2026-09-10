import 'package:flutter/material.dart';

import '../models/statistics_models.dart';

/// Tile para exibir as alternativas mais marcadas por questão.
///
/// Mostra: "Q7 — correta B" e abaixo os percentuais de cada alternativa.
class QuestionStatsTile extends StatelessWidget {
  const QuestionStatsTile({
    super.key,
    required this.stats,
  });

  final QuestionStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final percentages = stats.alternativePercentages.entries
        .map((e) => '${e.key} ${e.value}%')
        .join(' • ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Q${stats.questionNumber} — correta ${stats.correctAlternative}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            percentages,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
