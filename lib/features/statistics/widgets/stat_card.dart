import 'package:flutter/material.dart';

import '../../../core/widgets/app_card.dart';

/// Card de métrica com valor em destaque e label abaixo.
///
/// Usado para Média, Aproveitamento, Alunos, Provas, etc.
/// Segue o mesmo padrão visual do `_StatisticCard` do dashboard.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
