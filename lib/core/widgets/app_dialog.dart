import 'package:flutter/material.dart';

class AppDialog {
  const AppDialog._();

  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'OK',
    String? cancelLabel,
    VoidCallback? onConfirm,
    bool destructive = false,
  }) async {
    final confirmed = await confirm(
      context: context,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      destructive: destructive,
    );
    if (confirmed) onConfirm?.call();
  }

  /// Diálogo padrão de confirmação. Retorna `true` se o usuário confirmar.
  ///
  /// Com [destructive], o botão de confirmação fica na cor de erro
  /// (use para excluir, remover ou descartar dados).
  static Future<bool> confirm({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirmar',
    String? cancelLabel = 'Cancelar',
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            if (cancelLabel != null)
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(cancelLabel),
              ),
            FilledButton(
              style: destructive
                  ? FilledButton.styleFrom(
                      backgroundColor: colorScheme.error,
                      foregroundColor: colorScheme.onError,
                    )
                  : null,
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}
