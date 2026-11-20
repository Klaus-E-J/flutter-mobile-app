import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum AppStatusTone { neutral, success, warning }

/// Etiqueta compacta de status (ex.: "12 questões", "Sem questões").
class AppStatusPill extends StatelessWidget {
  const AppStatusPill({
    super.key,
    required this.label,
    this.icon,
    this.tone = AppStatusTone.neutral,
  });

  final String label;
  final IconData? icon;
  final AppStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (tone) {
      AppStatusTone.neutral => (
          colorScheme.secondaryContainer,
          colorScheme.onSecondaryContainer,
        ),
      AppStatusTone.success => (
          AppColors.successContainer,
          AppColors.onSuccessContainer,
        ),
      AppStatusTone.warning => (
          colorScheme.errorContainer,
          colorScheme.onErrorContainer,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
