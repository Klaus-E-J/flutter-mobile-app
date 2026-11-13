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
    final colorScheme = theme.colorScheme;

    final percentages = stats.alternativePercentages.entries
        .map((e) => '${e.key} ${e.value}%')
        .join(' • ');

    String effectiveMostMarked = stats.mostMarkedOption;
    int effectiveMostMarkedPct = stats.mostMarkedPercentage;
    if (effectiveMostMarked.isEmpty && stats.alternativePercentages.isNotEmpty) {
      var bestEntry = stats.alternativePercentages.entries.first;
      for (final entry in stats.alternativePercentages.entries) {
        if (entry.value > bestEntry.value) {
          bestEntry = entry;
        }
      }
      effectiveMostMarked = bestEntry.key;
      effectiveMostMarkedPct = bestEntry.value;
    }

    final mostMarkedIsCorrect =
        effectiveMostMarked.toUpperCase() == stats.correctAlternative.toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Q${stats.questionNumber} — correta ${stats.correctAlternative}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              if (effectiveMostMarked.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: mostMarkedIsCorrect
                        ? colorScheme.primaryContainer
                        : colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Mais marcada: $effectiveMostMarked ($effectiveMostMarkedPct%)',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: mostMarkedIsCorrect
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onErrorContainer,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            percentages,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (stats.alternativePercentages.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: stats.alternativePercentages.entries.map((entry) {
                final isCorrectAlt =
                    entry.key.toUpperCase() == stats.correctAlternative.toUpperCase();
                final isMostMarked =
                    entry.key == effectiveMostMarked && entry.value > 0;
                final count = stats.optionCounts[entry.key];
                final countLabel = count != null ? ' ($count)' : '';

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isCorrectAlt
                        ? colorScheme.primaryContainer.withValues(alpha: 0.6)
                        : (isMostMarked
                            ? colorScheme.errorContainer.withValues(alpha: 0.5)
                            : colorScheme.surfaceContainerHighest),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isCorrectAlt
                          ? colorScheme.primary
                          : (isMostMarked
                              ? colorScheme.error
                              : Colors.transparent),
                    ),
                  ),
                  child: Text(
                    '${entry.key}: ${entry.value}%$countLabel',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight:
                          (isCorrectAlt || isMostMarked) ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
