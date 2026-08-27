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
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            if (cancelLabel != null)
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(cancelLabel),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onConfirm?.call();
                },
                child: Text(confirmLabel),
              ),
          ],
        );
      },
    );
  }
}
