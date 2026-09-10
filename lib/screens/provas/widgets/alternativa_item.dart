import 'package:flutter/material.dart';

import '../models/questao_model.dart';

/// Widget para exibir e editar uma alternativa individual.
///
/// Mostra um radio button para seleção, campo de texto para o conteúdo
/// e um botão para remoção. A alternativa selecionada como correta
/// recebe destaque visual sutil.
class AlternativaItem extends StatelessWidget {
  const AlternativaItem({
    super.key,
    required this.alternativa,
    required this.indice,
    required this.isCorreta,
    required this.onTextoChanged,
    required this.onMarcarCorreta,
    required this.onRemover,
    required this.podeRemover,
    this.errorText,
  });

  final Alternativa alternativa;
  final int indice;
  final bool isCorreta;
  final ValueChanged<String> onTextoChanged;
  final VoidCallback onMarcarCorreta;
  final VoidCallback onRemover;
  final bool podeRemover;
  final String? errorText;

  /// Converte índice numérico para letra (0→A, 1→B, etc.).
  String _indiceParaLetra(int i) {
    return String.fromCharCode(65 + i); // A, B, C, D...
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorreta
              ? colorScheme.primary.withValues(alpha: 0.5)
              : colorScheme.outlineVariant,
          width: isCorreta ? 1.5 : 1,
        ),
        color: isCorreta
            ? colorScheme.primaryContainer.withValues(alpha: 0.15)
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Radio button para marcar como correta
            InkWell(
              onTap: onMarcarCorreta,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  isCorreta
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 20,
                  color: isCorreta
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ),

            // Letra da alternativa
            Text(
              '${_indiceParaLetra(indice)})',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isCorreta ? colorScheme.primary : colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 8),

            // Campo de texto da alternativa
            Expanded(
              child: TextField(
                controller: TextEditingController.fromValue(
                  TextEditingValue(
                    text: alternativa.texto,
                    selection: TextSelection.collapsed(
                      offset: alternativa.texto.length,
                    ),
                  ),
                ),
                onChanged: onTextoChanged,
                decoration: InputDecoration(
                  hintText: 'Alternativa ${_indiceParaLetra(indice)}',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  isDense: true,
                  errorText: errorText,
                  errorStyle: const TextStyle(fontSize: 11),
                ),
                style: theme.textTheme.bodyMedium,
              ),
            ),

            // Botão de remover alternativa
            if (podeRemover)
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: onRemover,
                tooltip: 'Remover alternativa',
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(
                  foregroundColor: colorScheme.error,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
