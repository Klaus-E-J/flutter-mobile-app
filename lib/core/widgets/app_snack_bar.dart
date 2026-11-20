import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';

enum AppSnackBarType { info, success, error }

/// Avisos rápidos padronizados (mesma forma, ícone e cor em todo o app).
abstract final class AppSnackBar {
  static void show(
    BuildContext context,
    String message, {
    AppSnackBarType type = AppSnackBarType.info,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final (Color? background, Color? foreground, IconData? icon) = switch (type) {
      AppSnackBarType.info => (null, null, null),
      AppSnackBarType.success => (
          AppColors.success,
          AppColors.onSuccess,
          AppIcons.success,
        ),
      AppSnackBarType.error => (
          colorScheme.error,
          colorScheme.onError,
          AppIcons.error,
        ),
    };

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: background,
          content: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: foreground, size: 20),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(message, style: TextStyle(color: foreground)),
              ),
            ],
          ),
        ),
      );
  }

  static void success(BuildContext context, String message) =>
      show(context, message, type: AppSnackBarType.success);

  static void error(BuildContext context, String message) =>
      show(context, message, type: AppSnackBarType.error);
}
