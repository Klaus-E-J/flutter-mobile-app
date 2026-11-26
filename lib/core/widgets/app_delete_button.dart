import 'package:flutter/material.dart';

import '../theme/app_icons.dart';

/// Botão padrão para excluir/remover: sempre a lixeira, sempre na cor de erro,
/// tanto na barra superior quanto nas linhas de uma lista.
class AppDeleteButton extends StatelessWidget {
  const AppDeleteButton({
    super.key,
    required this.tooltip,
    required this.onPressed,
    this.compact = false,
  });

  final String tooltip;
  final VoidCallback? onPressed;

  /// Versão menor para linhas densas (ex.: alternativas de uma questão).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(AppIcons.delete, size: compact ? 18 : null),
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: compact ? VisualDensity.compact : null,
      color: Theme.of(context).colorScheme.error,
    );
  }
}
