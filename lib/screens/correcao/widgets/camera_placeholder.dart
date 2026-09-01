import 'package:flutter/material.dart';

import '../models/correcao_models.dart';

/// Widget que simula um viewfinder de câmera.
///
/// Exibe um placeholder visual escuro com moldura e ícone de câmera,
/// junto com botões para simular leitura com sucesso ou erro.
/// Usado nas telas de leitura de QR Code, gabarito e captura de provas.
class CameraPlaceholder extends StatelessWidget {
  const CameraPlaceholder({
    super.key,
    required this.titulo,
    this.descricao,
    required this.status,
    this.onSimularSucesso,
    this.onSimularErro,
    this.mensagemErro,
    this.mensagemSucesso,
    this.child,
  });

  final String titulo;
  final String? descricao;
  final LeituraStatus status;
  final VoidCallback? onSimularSucesso;
  final VoidCallback? onSimularErro;
  final String? mensagemErro;
  final String? mensagemSucesso;

  /// Widget extra a exibir abaixo dos botões (ex: contador de progresso).
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // Instrução
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            children: [
              Text(
                titulo,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              if (descricao != null) ...[
                const SizedBox(height: 4),
                Text(
                  descricao!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),

        // Viewfinder simulado
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Frame / moldura do viewfinder
                _buildFrame(colorScheme),

                // Conteúdo central baseado no status
                _buildConteudoStatus(theme, colorScheme),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Feedback de erro/sucesso
        if (status == LeituraStatus.erro && mensagemErro != null)
          _buildFeedbackBanner(
            context,
            mensagemErro!,
            colorScheme.error,
            colorScheme.errorContainer,
            Icons.error_outline,
          ),

        if (status == LeituraStatus.sucesso && mensagemSucesso != null)
          _buildFeedbackBanner(
            context,
            mensagemSucesso!,
            colorScheme.primary,
            colorScheme.primaryContainer,
            Icons.check_circle_outline,
          ),

        // Botões de simulação
        if (status == LeituraStatus.aguardando ||
            status == LeituraStatus.erro)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                if (onSimularSucesso != null)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onSimularSucesso,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Simular Sucesso'),
                    ),
                  ),
                if (onSimularSucesso != null && onSimularErro != null)
                  const SizedBox(width: 12),
                if (onSimularErro != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onSimularErro,
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Simular Erro'),
                    ),
                  ),
              ],
            ),
          ),

        // Widget extra (ex: progresso)
        ?child,

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFrame(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildConteudoStatus(ThemeData theme, ColorScheme colorScheme) {
    switch (status) {
      case LeituraStatus.aguardando:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 48,
              color: Colors.white.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            Text(
              'Aponte a câmera',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        );

      case LeituraStatus.processando:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Processando...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        );

      case LeituraStatus.sucesso:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              size: 56,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Leitura realizada!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );

      case LeituraStatus.erro:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 56,
              color: colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              'Falha na leitura',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
    }
  }

  Widget _buildFeedbackBanner(
    BuildContext context,
    String mensagem,
    Color iconColor,
    Color bgColor,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              mensagem,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: iconColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
