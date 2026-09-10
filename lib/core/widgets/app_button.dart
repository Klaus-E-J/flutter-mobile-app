import 'package:flutter/material.dart';

enum AppButtonVariant { primary, secondary, text }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.expanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final Widget button;
    final effectiveOnPressed = isLoading ? null : onPressed;

    switch (variant) {
      case AppButtonVariant.primary:
        button = icon != null
            ? FilledButton.icon(
                onPressed: effectiveOnPressed,
                icon: _buildIcon(),
                label: Text(label),
              )
            : FilledButton(
                onPressed: effectiveOnPressed,
                child: _buildLabel(),
              );

      case AppButtonVariant.secondary:
        button = icon != null
            ? OutlinedButton.icon(
                onPressed: effectiveOnPressed,
                icon: _buildIcon(),
                label: Text(label),
              )
            : OutlinedButton(
                onPressed: effectiveOnPressed,
                child: _buildLabel(),
              );

      case AppButtonVariant.text:
        button = icon != null
            ? TextButton.icon(
                onPressed: effectiveOnPressed,
                icon: _buildIcon(),
                label: Text(label),
              )
            : TextButton(
                onPressed: effectiveOnPressed,
                child: _buildLabel(),
              );
    }

    if (!expanded) return button;
    return SizedBox(width: double.infinity, child: button);
  }

  Widget _buildIcon() {
    if (isLoading) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return Icon(icon);
  }

  Widget _buildLabel() {
    if (isLoading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      );
    }
    return Text(label);
  }
}
