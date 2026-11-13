import 'package:flutter/material.dart';

import '../models/questao_model.dart';

/// Widget para exibir e editar uma alternativa individual.
///
/// Mostra um radio button para seleção, campo de texto para o conteúdo
/// e um botão para remoção. A alternativa selecionada como correta
/// recebe destaque visual sutil.
class AlternativaItem extends StatefulWidget {
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

  @override
  State<AlternativaItem> createState() => _AlternativaItemState();
}

class _AlternativaItemState extends State<AlternativaItem> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.alternativa.texto);
  }

  @override
  void didUpdateWidget(covariant AlternativaItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.alternativa.id != widget.alternativa.id ||
        _controller.text != widget.alternativa.texto) {
      final previousSelection = _controller.selection;
      _controller.text = widget.alternativa.texto;
      final newOffset = previousSelection.baseOffset.clamp(
        0,
        widget.alternativa.texto.length,
      );
      _controller.selection = TextSelection.collapsed(offset: newOffset);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Converte índice numérico para letra (0→A, 1→B, etc.).
  String _indiceParaLetra(int i) {
    return String.fromCharCode(65 + i); // A, B, C, D, E
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isCorreta = widget.isCorreta;

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
              onTap: widget.onMarcarCorreta,
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
              '${_indiceParaLetra(widget.indice)})',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isCorreta ? colorScheme.primary : colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 8),

            // Campo de texto da alternativa
            Expanded(
              child: TextField(
                controller: _controller,
                onChanged: widget.onTextoChanged,
                decoration: InputDecoration(
                  hintText: 'Alternativa ${_indiceParaLetra(widget.indice)}',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  isDense: true,
                  errorText: widget.errorText,
                  errorStyle: const TextStyle(fontSize: 11),
                ),
                style: theme.textTheme.bodyMedium,
              ),
            ),

            // Botão de remover alternativa
            if (widget.podeRemover)
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: widget.onRemover,
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
