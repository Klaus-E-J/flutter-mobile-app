import 'package:flutter/material.dart';

import '../models/statistics_models.dart';

/// Tile para o histórico do aluno por disciplina.
///
/// Exibe nome da disciplina e nota no formato "Matemática — 8,5".
/// Preparado com [onTap] para futura navegação ao FE-10 (Resultados do aluno).
class SubjectHistoryTile extends StatelessWidget {
  const SubjectHistoryTile({
    super.key,
    required this.result,
    this.onTap,
  });

  final SubjectResult result;

  /// Callback para navegação futura ao resultado detalhado (FE-10).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Formata a nota com vírgula (padrão BR).
    final gradeText = result.grade.toStringAsFixed(1).replaceAll('.', ',');

    final tile = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${result.subjectName} — $gradeText',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          if (onTap != null)
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
        ],
      ),
    );

    if (onTap == null) return tile;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: tile,
    );
  }
}
