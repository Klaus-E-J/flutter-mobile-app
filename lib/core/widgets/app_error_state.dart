import 'package:flutter/material.dart';

import 'app_button.dart';

class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    this.title = 'Não foi possível carregar os dados',
    this.description,
    this.onRetry,
  });

  final String title;
  final String? description;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              AppButton(
                label: 'Tentar novamente',
                icon: Icons.refresh,
                variant: AppButtonVariant.secondary,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
