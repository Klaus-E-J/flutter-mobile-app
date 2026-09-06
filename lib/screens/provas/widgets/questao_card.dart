import 'package:flutter/material.dart';

import '../models/questao_model.dart';
import 'alternativa_item.dart';

/// Card expansível que exibe e permite editar uma questão completa.
///
/// Contém o campo de enunciado, a lista de alternativas, botões para
/// adicionar/remover alternativas e indicadores visuais de validação.
class QuestaoCard extends StatefulWidget {
  const QuestaoCard({
    super.key,
    required this.questao,
    required this.numero,
    required this.onChanged,
    required this.onRemover,
  });

  final Questao questao;
  final int numero;
  final VoidCallback onChanged;
  final VoidCallback onRemover;

  @override
  State<QuestaoCard> createState() => _QuestaoCardState();
}

class _QuestaoCardState extends State<QuestaoCard> {
  late TextEditingController _enunciadoController;
  bool _expandido = true;
  List<String> _erros = [];

  @override
  void initState() {
    super.initState();
    _enunciadoController = TextEditingController(
      text: widget.questao.enunciado,
    );
  }

  @override
  void didUpdateWidget(covariant QuestaoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.questao.id != widget.questao.id) {
      _enunciadoController.text = widget.questao.enunciado;
    }
  }

  @override
  void dispose() {
    _enunciadoController.dispose();
    super.dispose();
  }

  void _validar() {
    setState(() {
      _erros = widget.questao.validar();
    });
  }

  void _onEnunciadoChanged(String value) {
    widget.questao.enunciado = value;
    widget.onChanged();
    // Limpa erros ao editar
    if (_erros.isNotEmpty) _validar();
  }

  void _onAlternativaTextoChanged(int index, String value) {
    widget.questao.alternativas[index].texto = value;
    widget.onChanged();
    if (_erros.isNotEmpty) _validar();
  }

  void _marcarAlternativaCorreta(int index) {
    setState(() {
      for (int i = 0; i < widget.questao.alternativas.length; i++) {
        widget.questao.alternativas[i].correta = (i == index);
      }
    });
    widget.onChanged();
    if (_erros.isNotEmpty) _validar();
  }

  void _adicionarAlternativa() {
    if (widget.questao.alternativas.length >= Questao.maximoAlternativas) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Máximo de ${Questao.maximoAlternativas} alternativas atingido.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      widget.questao.alternativas.add(
        Alternativa(id: IdGenerator.generate(), texto: ''),
      );
    });
    widget.onChanged();
  }

  void _removerAlternativa(int index) {
    if (widget.questao.alternativas.length <= Questao.minimoAlternativas) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Mínimo de ${Questao.minimoAlternativas} alternativas.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      widget.questao.alternativas.removeAt(index);
    });
    widget.onChanged();
    if (_erros.isNotEmpty) _validar();
  }

  void _confirmarRemocaoQuestao() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover questão'),
        content: Text(
          'Deseja remover a Questão ${widget.numero}? '
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.onRemover();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isValida = widget.questao.isValid;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _erros.isNotEmpty
              ? colorScheme.error.withValues(alpha: 0.5)
              : colorScheme.outlineVariant,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header do card
          _buildHeader(theme, colorScheme, isValida),

          // Conteúdo expansível
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildConteudo(theme, colorScheme),
            crossFadeState: _expandido
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isValida,
  ) {
    return InkWell(
      onTap: () => setState(() => _expandido = !_expandido),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Badge do número da questão
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _erros.isNotEmpty
                    ? colorScheme.errorContainer
                    : colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                '${widget.numero}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _erros.isNotEmpty
                      ? colorScheme.onErrorContainer
                      : colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Título / preview do enunciado
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.questao.enunciado.isEmpty
                        ? 'Questão ${widget.numero}'
                        : widget.questao.enunciado,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: widget.questao.enunciado.isEmpty
                          ? colorScheme.onSurface.withValues(alpha: 0.5)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.questao.alternativas.length} alternativas'
                    '${widget.questao.alternativaCorreta != null ? ' · 1 correta' : ''}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Ícone de validação
            if (_erros.isNotEmpty)
              Tooltip(
                message: _erros.join('\n'),
                child: Icon(
                  Icons.warning_amber_rounded,
                  size: 20,
                  color: colorScheme.error,
                ),
              ),

            // Botão expandir/recolher
            AnimatedRotation(
              turns: _expandido ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.expand_more,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConteudo(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Campo do enunciado
          TextField(
            controller: _enunciadoController,
            onChanged: _onEnunciadoChanged,
            maxLines: 3,
            minLines: 1,
            decoration: InputDecoration(
              labelText: 'Enunciado',
              hintText: 'Digite o enunciado da questão...',
              alignLabelWithHint: true,
              errorText: _erros.isNotEmpty &&
                      widget.questao.enunciado.trim().isEmpty
                  ? 'O enunciado não pode ser vazio.'
                  : null,
            ),
          ),
          const SizedBox(height: 20),

          // Título da seção de alternativas
          Row(
            children: [
              Text(
                'Alternativas',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                'Toque no rádio para marcar a correta',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),

          // Erro se nenhuma alternativa está marcada como correta
          if (_erros.isNotEmpty &&
              widget.questao.alternativaCorreta == null) ...[
            const SizedBox(height: 4),
            Text(
              'Marque exatamente uma alternativa como correta.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Lista de alternativas
          ...List.generate(
            widget.questao.alternativas.length,
            (i) {
              final alt = widget.questao.alternativas[i];
              return AlternativaItem(
                key: ValueKey(alt.id),
                alternativa: alt,
                indice: i,
                isCorreta: alt.correta,
                onTextoChanged: (v) => _onAlternativaTextoChanged(i, v),
                onMarcarCorreta: () => _marcarAlternativaCorreta(i),
                onRemover: () => _removerAlternativa(i),
                podeRemover: widget.questao.alternativas.length >
                    Questao.minimoAlternativas,
                errorText: _erros.isNotEmpty && alt.texto.trim().isEmpty
                    ? 'Texto vazio'
                    : null,
              );
            },
          ),

          const SizedBox(height: 8),

          // Botões de ação
          Row(
            children: [
              // Adicionar alternativa
              if (widget.questao.alternativas.length <
                  Questao.maximoAlternativas)
                TextButton.icon(
                  onPressed: _adicionarAlternativa,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Alternativa'),
                ),

              const Spacer(),

              // Validar
              TextButton.icon(
                onPressed: _validar,
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Validar'),
              ),

              // Remover questão
              TextButton.icon(
                onPressed: _confirmarRemocaoQuestao,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Remover'),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.error,
                ),
              ),
            ],
          ),

          // Exibição dos erros de validação
          if (_erros.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 16,
                        color: colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Problemas encontrados:',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ...List.generate(
                    _erros.length,
                    (i) => Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '• ${_erros[i]}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
