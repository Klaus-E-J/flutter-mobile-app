import 'package:flutter/material.dart';

enum AppButtonVariant {
  primary,
  secondary,
  text,
}

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

    switch (variant) {
      case AppButtonVariant.primary:
        button = FilledButton.icon(
          onPressed: isLoading ? null : onPressed,
          icon: _buildIcon(),
          label: _buildLabel(),
        );
        break;

      case AppButtonVariant.secondary:
        button = OutlinedButton.icon(
          onPressed: isLoading ? null : onPressed,
          icon: _buildIcon(),
          label: _buildLabel(),
        );
        break;

      case AppButtonVariant.text:
        button = TextButton.icon(
          onPressed: isLoading ? null : onPressed,
          icon: _buildIcon(),
          label: _buildLabel(),
        );
        break;
    }

    if (!expanded) {
      return button;
    }

    return SizedBox(
      width: double.infinity,
      child: button,
    );
  }

  Widget _buildIcon() {
    if (isLoading) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
        ),
      );
    }

    if (icon != null) {
      return Icon(icon);
    }

    return const SizedBox.shrink();
  }

  Widget _buildLabel() {
    return Text(label);
  }
}
