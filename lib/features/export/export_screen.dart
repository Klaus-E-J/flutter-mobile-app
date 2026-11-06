import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_loading.dart';
import '../correction/data/submission_repository.dart';
import 'services/result_export_service.dart';

/// Callback para compartilhamento ou salvamento de arquivo exportado.
typedef ShareExportedFileCallback = Future<void> Function(
  Uint8List bytes,
  String fileName,
  String mimeType,
);

/// Tela de Exportação de Resultados (N3-08).
///
/// Extrai submissões reais do Cloud Firestore (`SubmissionRepository`),
/// filtra por avaliação/turma e gera planilhas Excel (.xlsx) ou CSV (.csv)
/// utilizando `ResultExportService` e `SharePlus`.
class ExportScreen extends StatefulWidget {
  const ExportScreen({
    super.key,
    this.initialSubmissions,
    this.onShareExportedFile,
  });

  final List<SubmissionRecord>? initialSubmissions;
  final ShareExportedFileCallback? onShareExportedFile;

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final ResultExportService _exportService = const ResultExportService();

  List<SubmissionRecord> _allSubmissions = [];
  String _selectedExamKey = 'ALL';
  bool _loadingSubmissions = true;

  // Seleção de conteúdo
  bool _incluirResultados = true;
  bool _incluirEstatisticas = false;
  bool _incluirGabarito = false;

  // Formato do arquivo
  _ExportFormat _formato = _ExportFormat.excel;

  _ExportStatus _status = _ExportStatus.idle;
  String? _errorMessage;
  Uint8List? _generatedBytes;
  String? _generatedFileName;
  String? _savedFilePath;

  bool get _hasSelection =>
      _incluirResultados || _incluirEstatisticas || _incluirGabarito;

  @override
  void initState() {
    super.initState();
    _carregarSubmissoes();
  }

  Future<void> _carregarSubmissoes() async {
    if (widget.initialSubmissions != null) {
      setState(() {
        _allSubmissions = widget.initialSubmissions!;
        _loadingSubmissions = false;
      });
      return;
    }

    setState(() => _loadingSubmissions = true);
    try {
      final subs = await SubmissionRepository().getSubmissions();
      if (!mounted) return;
      setState(() {
        _allSubmissions = subs;
        _loadingSubmissions = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _allSubmissions = [];
        _loadingSubmissions = false;
      });
    }
  }

  List<SubmissionRecord> get _filteredSubmissions {
    if (_selectedExamKey == 'ALL') return _allSubmissions;
    return _allSubmissions
        .where((s) => '${s.examId}|${s.classId}' == _selectedExamKey)
        .toList();
  }

  Map<String, String> get _examOptions {
    final map = <String, String>{'ALL': 'Todas as avaliações corrigidas'};
    for (final s in _allSubmissions) {
      final key = '${s.examId}|${s.classId}';
      map.putIfAbsent(key, () => '${s.examTitle} • ${s.className}');
    }
    return map;
  }

  Future<void> _iniciarExportacao() async {
    if (!_hasSelection) return;

    setState(() {
      _status = _ExportStatus.loading;
      _errorMessage = null;
      _generatedBytes = null;
      _generatedFileName = null;
      _savedFilePath = null;
    });

    try {
      final targetSubs = _filteredSubmissions;
      final timestamp = DateTime.now()
          .toIso8601String()
          .substring(0, 19)
          .replaceAll(':', '-');

      late final Uint8List bytes;
      late final String fileName;

      if (_formato == _ExportFormat.excel) {
        bytes = _exportService.generateExcelBytes(
          submissions: targetSubs,
          includeStudentResults: _incluirResultados,
          includeStatistics: _incluirEstatisticas,
          includeAnswerMatrix: _incluirGabarito,
        );
        fileName = 'avalia_pro_resultados_$timestamp.xlsx';
      } else {
        bytes = _exportService.generateCsvBytes(
          submissions: targetSubs,
          includeStudentResults: _incluirResultados,
          includeStatistics: _incluirEstatisticas,
          includeAnswerMatrix: _incluirGabarito,
        );
        fileName = 'avalia_pro_resultados_$timestamp.csv';
      }

      String? localPath;
      if (widget.onShareExportedFile == null) {
        try {
          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}${Platform.pathSeparator}$fileName');
          await file.writeAsBytes(bytes, flush: true);
          localPath = file.path;
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() {
        _generatedBytes = bytes;
        _generatedFileName = fileName;
        _savedFilePath = localPath;
        _status = _ExportStatus.success;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _status = _ExportStatus.error;
        _errorMessage = 'Não foi possível gerar o arquivo: $error';
      });
    }
  }

  void _resetar() {
    setState(() {
      _status = _ExportStatus.idle;
      _errorMessage = null;
      _generatedBytes = null;
      _generatedFileName = null;
      _savedFilePath = null;
    });
  }

  Future<void> _compartilhar() async {
    final bytes = _generatedBytes;
    final fileName = _generatedFileName;
    if (bytes == null || fileName == null) return;

    final mimeType = _formato == _ExportFormat.excel
        ? 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
        : 'text/csv';

    if (widget.onShareExportedFile != null) {
      await widget.onShareExportedFile!(bytes, fileName, mimeType);
      return;
    }

    try {
      final xFile = _savedFilePath != null
          ? XFile(_savedFilePath!, mimeType: mimeType, name: fileName)
          : XFile.fromData(bytes, mimeType: mimeType, name: fileName);

      await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          fileNameOverrides: [fileName],
          subject: 'Resultados Avalia Pro - $fileName',
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _savedFilePath != null
                ? 'Arquivo salvo em: $_savedFilePath'
                : 'Erro ao abrir compartilhamento: $error',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exportação'),
      ),
      body: SafeArea(
        child: _loadingSubmissions
            ? const AppLoading(message: 'Carregando dados para exportação...')
            : _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    switch (_status) {
      case _ExportStatus.loading:
        return const AppLoading(message: 'Gerando planilha...');

      case _ExportStatus.success:
        return _buildSuccess();

      case _ExportStatus.error:
        return _buildError();

      case _ExportStatus.idle:
        return _buildSelector();
    }
  }

  Widget _buildSelector() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final options = _examOptions;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Exportar',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Gere planilhas Excel (.xlsx) ou CSV (.csv) com os resultados reais das avaliações.',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 20),
        Text(
          'Avaliação / Turma',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: options.containsKey(_selectedExamKey)
              ? _selectedExamKey
              : 'ALL',
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          items: options.entries.map((entry) {
            return DropdownMenuItem(
              value: entry.key,
              child: Text(
                entry.value,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedExamKey = val);
            }
          },
        ),
        const SizedBox(height: 6),
        Text(
          '${_filteredSubmissions.length} submissão(ões) selecionada(s) para exportação',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Conteúdo',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildOpcao(
          icon: Icons.assignment_outlined,
          titulo: 'Resultados dos alunos',
          descricao: 'Notas, variantes, acertos e situação de cada aluno.',
          valor: _incluirResultados,
          onChanged: (v) => setState(() => _incluirResultados = v),
        ),
        const SizedBox(height: 10),
        _buildOpcao(
          icon: Icons.bar_chart_outlined,
          titulo: 'Estatísticas da turma',
          descricao: 'Médias, taxa de aprovação e desempenho por questão.',
          valor: _incluirEstatisticas,
          onChanged: (v) => setState(() => _incluirEstatisticas = v),
        ),
        const SizedBox(height: 10),
        _buildOpcao(
          icon: Icons.fact_check_outlined,
          titulo: 'Gabarito e questões',
          descricao: 'Matriz detalhada de alternativa marcada vs. gabarito por questão.',
          valor: _incluirGabarito,
          onChanged: (v) => setState(() => _incluirGabarito = v),
        ),
        const SizedBox(height: 28),
        Text(
          'Formato',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _buildFormatoOpcao(
                  formato: _ExportFormat.excel,
                  label: 'Excel (.xlsx)',
                  icon: Icons.table_chart_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFormatoOpcao(
                  formato: _ExportFormat.csv,
                  label: 'CSV (.csv)',
                  icon: Icons.description_outlined,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        AppButton(
          label: 'Exportar e compartilhar',
          icon: Icons.upload_outlined,
          expanded: true,
          onPressed: _hasSelection ? _iniciarExportacao : null,
        ),
        if (!_hasSelection) ...[
          const SizedBox(height: 8),
          Text(
            'Selecione ao menos um tipo de conteúdo.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFormatoOpcao({
    required _ExportFormat formato,
    required String label,
    required IconData icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _formato == formato;

    return InkWell(
      onTap: () => setState(() => _formato = formato),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : null,
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpcao({
    required IconData icon,
    required String titulo,
    required String descricao,
    required bool valor,
    required ValueChanged<bool> onChanged,
  }) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: CheckboxListTile(
        value: valor,
        onChanged: (v) => onChanged(v ?? false),
        controlAffinity: ListTileControlAffinity.trailing,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              titulo,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2, left: 26),
          child: Text(
            descricao,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizeKb = ((_generatedBytes?.length ?? 0) / 1024).toStringAsFixed(1);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                size: 40,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Arquivo gerado!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_generatedFileName ?? ''} ($sizeKb KB • ${_filteredSubmissions.length} registros)',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'O arquivo foi gerado com sucesso e está pronto para '
              'ser compartilhado ou salvo.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            AppButton(
              label: 'Compartilhar / Salvar',
              icon: Icons.share_outlined,
              expanded: true,
              onPressed: _compartilhar,
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Nova exportação',
              variant: AppButtonVariant.secondary,
              icon: Icons.refresh,
              expanded: true,
              onPressed: _resetar,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 56,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Falha na exportação',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 32),
            AppButton(
              label: 'Tentar novamente',
              icon: Icons.refresh,
              expanded: true,
              onPressed: _iniciarExportacao,
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Cancelar',
              variant: AppButtonVariant.text,
              expanded: true,
              onPressed: _resetar,
            ),
          ],
        ),
      ),
    );
  }
}

enum _ExportStatus { idle, loading, success, error }

enum _ExportFormat { excel, csv }
