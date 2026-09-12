import 'package:flutter/material.dart';

import '../../core/widgets/app_card.dart';
import 'data/student_import_parser.dart';

enum _ImportStep { selecting, loading, preview, error }

/// Fluxo de importação de alunos: selecionar arquivo, mostrar prévia
/// dos nomes, confirmar ou cancelar, e exibir erro para arquivo
/// inválido. Retorna a lista de nomes confirmados (ou `null` se
/// cancelado) via `Navigator.pop`.
///
/// Use `showImportStudentsSheet` para abrir.
class ImportStudentsSheet extends StatefulWidget {
  const ImportStudentsSheet({
    super.key,
    this.parser = const MockStudentImportParser(),
  });

  final StudentImportParser parser;

  @override
  State<ImportStudentsSheet> createState() => _ImportStudentsSheetState();
}

class _ImportStudentsSheetState extends State<ImportStudentsSheet> {
  _ImportStep _step = _ImportStep.selecting;
  List<String> _previewNames = const [];
  String? _errorMessage;
  String? _selectedFileName;

  Future<void> _handleFileSelected(String fileId) async {
    setState(() {
      _step = _ImportStep.loading;
    });

    final result = await widget.parser.parse(fileId);

    if (!mounted) return;

    if (!result.isValid) {
      setState(() {
        _step = _ImportStep.error;
        _errorMessage = result.errorMessage;
      });
      return;
    }

    setState(() {
      _step = _ImportStep.preview;
      _previewNames = result.studentNames;
      _selectedFileName = result.fileName;
    });
  }

  void _handleRetry() {
    setState(() {
      _step = _ImportStep.selecting;
      _errorMessage = null;
    });
  }

  void _handleCancel() {
    Navigator.of(context).pop();
  }

  void _handleConfirm() {
    Navigator.of(context).pop(_previewNames);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Text(
              'Importar lista de alunos',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStepContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(BuildContext context) {
    switch (_step) {
      case _ImportStep.selecting:
        return _buildSelectingStep(context);
      case _ImportStep.loading:
        return _buildLoadingStep(context);
      case _ImportStep.preview:
        return _buildPreviewStep(context);
      case _ImportStep.error:
        return _buildErrorStep(context);
    }
  }

  Widget _buildSelectingStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Selecione um arquivo .csv ou .xlsx com a lista de alunos.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        for (final file in widget.parser.availableFiles) ...[
          _FileOptionTile(
            option: file,
            onTap: () => _handleFileSelected(file.id),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _handleCancel,
            child: const Text('Cancelar'),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingStep(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Lendo arquivo...'),
        ],
      ),
    );
  }

  Widget _buildPreviewStep(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.check_circle_outline, color: colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${_previewNames.length} alunos encontrados em '
                '$_selectedFileName',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 260),
          child: AppCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _previewNames.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.person_outline),
                  title: Text(_previewNames[index]),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _handleCancel,
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _handleConfirm,
                child: const Text('Confirmar importação'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorStep(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _errorMessage ?? 'Não foi possível ler o arquivo.',
                  style: TextStyle(color: colorScheme.onErrorContainer),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _handleCancel,
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _handleRetry,
                child: const Text('Tentar novamente'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FileOptionTile extends StatelessWidget {
  const _FileOptionTile({required this.option, required this.onTap});

  final ImportFileOption option;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(option.icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(child: Text(option.label)),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

/// Abre o fluxo de importação como um modal bottom sheet.
/// Retorna a lista de nomes confirmados, ou `null` se cancelado.
Future<List<String>?> showImportStudentsSheet(
  BuildContext context, {
  StudentImportParser parser = const MockStudentImportParser(),
}) {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => ImportStudentsSheet(parser: parser),
  );
}
