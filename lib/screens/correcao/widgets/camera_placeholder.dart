import 'package:flutter/material.dart';

import '../models/correcao_models.dart';

/// Widget reutilizável que simula o viewfinder de câmera.
///
/// Layout fiel ao Figma: container escuro com moldura interna
/// e texto/ícone centralizado. Sem botões — o botão de ação
/// fica na tela que consome este widget.
class CameraPlaceholder extends StatelessWidget {
  const CameraPlaceholder({
    super.key,
    required this.label,
    this.status = LeituraStatus.aguardando,
    this.icon,
  });

  /// Texto exibido no centro do viewfinder (ex: "GABARITO", "OMR").
  final String label;

  /// Estado atual da leitura (altera o conteúdo visual).
  final LeituraStatus status;

  /// Ícone opcional exibido ao lado do label.
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Moldura interna (scan frame)
            Container(
              margin: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 2,
                ),
              ),
            ),

            // Conteúdo central
            _buildConteudo(colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildConteudo(ColorScheme colorScheme) {
    switch (status) {
      case LeituraStatus.aguardando:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[icon!, const SizedBox(width: 8)],
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );

      case LeituraStatus.processando:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Processando...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        );

      case LeituraStatus.sucesso:
        return Icon(
          Icons.check_circle,
          size: 56,
          color: colorScheme.primary,
        );

      case LeituraStatus.erro:
        return Icon(
          Icons.error_outline,
          size: 56,
          color: colorScheme.error,
        );
    }
  }
}
