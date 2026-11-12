import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_loading.dart';
import 'data/class_repository.dart';
import 'services/student_import_service.dart';

/// Dados de um arquivo selecionado para importação.
typedef PickedImportFile = ({String name, Uint8List bytes});

/// Tela de Importação de Alunos (N3-01).
///
/// Permite selecionar um arquivo CSV ou Excel (.xlsx), validar linhas,
/// detectar duplicidades e importar alunos em lote para uma turma no Cloud Firestore.
class ImportacaoAlunosScreen extends StatefulWidget {
  const ImportacaoAlunosScreen({
    super.key,
    required this.nomeTurma,
    required this.classId,
    this.existingStudents,
    this.onPickFile,
    this.onSaveStudents,
  });

  final String nomeTurma;
  final String classId;
  final List<StudentRecord>? existingStudents;
  final Future<PickedImportFile?> Function()? onPickFile;
  final Future<void> Function(List<StudentRecord> students)? onSaveStudents;

  @override
  State<ImportacaoAlunosScreen> createState() => _ImportacaoAlunosScreenState();
}

class _ImportacaoAlunosScreenState extends State<ImportacaoAlunosScreen> {
  final StudentImportService _importService = const StudentImportService();

  _ImportStep _step = _ImportStep.selecao;
  StudentImportResult? _importResult;
  List<StudentRecord> _selectedStudents = [];
  bool _isLoading = false;
  String? _errorMessage;

  Future<PickedImportFile?> _defaultPickFile() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv', 'xlsx', 'xls'],
    );
    if (files.isEmpty) return null;

    final file = files.first;
    final bytes = await file.readAsBytes();
    return (name: file.name, bytes: bytes);
  }

  Future<void> _selecionarArquivo() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final pickFn = widget.onPickFile ?? _defaultPickFile;
      final picked = await pickFn();
      if (!mounted) return;

      if (picked == null) {
        setState(() => _isLoading = false);
        return;
      }

      List<StudentRecord> existing = widget.existingStudents ?? const [];
      if (widget.existingStudents == null && widget.onSaveStudents == null) {
        try {
          existing = await ClassRepository().getStudents(widget.classId);
        } catch (_) {
          existing = const [];
        }
      }

      final parsed = _importService.parseBytes(
        bytes: picked.bytes,
        fileName: picked.name,
        existingStudents: existing,
      );

      if (!mounted) return;

      if (parsed.fatalError != null) {
        setState(() {
          _isLoading = false;
          _errorMessage = parsed.fatalError;
          _step = _ImportStep.erro;
        });
        return;
      }

      setState(() {
        _isLoading = false;
        _importResult = parsed;
        _selectedStudents = List<StudentRecord>.from(parsed.validStudents);
        _step = _ImportStep.previa;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro ao ler o arquivo: $error';
        _step = _ImportStep.erro;
      });
    }
  }

  void _removerAlunoDaPrevia(int index) {
    setState(() {
      _selectedStudents.removeAt(index);
    });
  }

  Future<void> _confirmarImportacao() async {
    if (_selectedStudents.isEmpty) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar importação'),
        content: Text(
          'Serão adicionados ${_selectedStudents.length} aluno(s) à turma '
          '"${widget.nomeTurma}". Deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Importar'),
          ),
        ],
      ),
    );

    if (!(confirmar ?? false) || !mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _step = _ImportStep.importando;
    });

    try {
      if (widget.onSaveStudents != null) {
        await widget.onSaveStudents!(_selectedStudents);
      } else {
        await ClassRepository().addStudents(
          classId: widget.classId,
          students: _selectedStudents,
        );
      }
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _step = _ImportStep.sucesso;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Não foi possível salvar os alunos: $error';
        _step = _ImportStep.erro;
      });
    }
  }

  void _reiniciar() {
    setState(() {
      _step = _ImportStep.selecao;
      _importResult = null;
      _selectedStudents = [];
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == _ImportStep.selecao || _step == _ImportStep.sucesso,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final result = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Cancelar importação?'),
            content: const Text(
              'Se sair agora, os dados selecionados serão descartados.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Continuar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Sair'),
              ),
            ],
          ),
        );
        if ((result ?? false) && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Importar alunos'),
        ),
        body: SafeArea(
          child: _isLoading && _step == _ImportStep.importando
              ? const AppLoading(message: 'Importando alunos...')
              : _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_step) {
      case _ImportStep.selecao:
        return _buildSelecao();
      case _ImportStep.previa:
        return _buildPrevia();
      case _ImportStep.importando:
        return const AppLoading(message: 'Importando alunos...');
      case _ImportStep.sucesso:
        return _buildSucesso();
      case _ImportStep.erro:
        return _buildErro();
    }
  }

  Widget _buildSelecao() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Importar lista de alunos',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Adicione vários alunos de uma vez enviando um arquivo CSV ou Excel (.xlsx).',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 32),
        AppCard(
          onTap: _isLoading ? null : _selecionarArquivo,
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.upload_file_outlined,
                size: 48,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Selecionar arquivo',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Toque para escolher um arquivo CSV ou XLSX do seu dispositivo.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (_isLoading) ...[
                const SizedBox(height: 20),
                const CircularProgressIndicator(),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Formato esperado',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFormatoItem(
                'Colunas suportadas',
                'Nome completo (obrigatório), Matrícula/RA (opcional) e E-mail (opcional)',
                Icons.person_outlined,
              ),
              const SizedBox(height: 10),
              _buildFormatoItem(
                'Cabeçalho e delimitador',
                'Cabeçalho detectado automaticamente; suporta vírgula (,), ponto e vírgula (;) ou Excel (.xlsx)',
                Icons.table_rows_outlined,
              ),
              const SizedBox(height: 10),
              _buildFormatoItem(
                'Validação de duplicados',
                'Nomes ou matrículas repetidas são filtrados automaticamente antes de importar',
                Icons.verified_outlined,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormatoItem(String label, String descricao, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                descricao,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrevia() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final result = _importResult!;
    final totalProblemas = result.duplicates.length + result.rejectedRows.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Prévia da importação',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Arquivo: ${result.fileName}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(
                      Icons.people_outlined,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${_selectedStudents.length} aluno(s) válido(s) para adicionar '
                        'à turma "${widget.nomeTurma}"',
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (totalProblemas > 0 || result.warnings.isNotEmpty) ...[
                const SizedBox(height: 8),
                AppCard(
                  color: colorScheme.errorContainer.withValues(alpha: 0.25),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: colorScheme.error,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${result.duplicates.length} duplicado(s) ignorado(s) • '
                              '${result.rejectedRows.length} linha(s) inválida(s)',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                      for (final issue in result.duplicates.take(3))
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 26),
                          child: Text(
                            '• Linha ${issue.lineNumber}: ${issue.rawDescription} (${issue.reason})',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      for (final issue in result.rejectedRows.take(3))
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 26),
                          child: Text(
                            '• Linha ${issue.lineNumber}: ${issue.reason}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      for (final warning in result.warnings.take(2))
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 26),
                          child: Text(
                            '• $warning',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),
        Expanded(
          child: _selectedStudents.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Nenhum aluno novo e válido encontrado para importar.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: _selectedStudents.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final student = _selectedStudents[index];
                    final subtitleParts = <String>[
                      if (student.matricula.isNotEmpty)
                        'Matrícula: ${student.matricula}',
                      if (student.email.isNotEmpty) student.email,
                    ];
                    return AppCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: colorScheme.primaryContainer,
                            child: Text(
                              student.name[0].toUpperCase(),
                              style: TextStyle(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  student.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (subtitleParts.isNotEmpty)
                                  Text(
                                    subtitleParts.join(' • '),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              size: 18,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            tooltip: 'Remover da importação',
                            onPressed: () => _removerAlunoDaPrevia(index),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppButton(
                  label: 'Confirmar importação',
                  icon: Icons.check,
                  expanded: true,
                  onPressed:
                      _selectedStudents.isNotEmpty ? _confirmarImportacao : null,
                ),
                const SizedBox(height: 8),
                AppButton(
                  label: 'Cancelar',
                  variant: AppButtonVariant.text,
                  expanded: true,
                  onPressed: _reiniciar,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSucesso() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
              'Importação concluída!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_selectedStudents.length} aluno(s) foram adicionados à turma '
              '"${widget.nomeTurma}".',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            AppButton(
              label: 'Voltar para a turma',
              icon: Icons.arrow_back,
              expanded: true,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErro() {
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
              'Falha na importação',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ??
                  'Não foi possível importar os alunos. Verifique o arquivo e '
                      'tente novamente.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            if (_selectedStudents.isNotEmpty) ...[
              AppButton(
                label: 'Tentar novamente',
                icon: Icons.refresh,
                expanded: true,
                onPressed: _confirmarImportacao,
              ),
              const SizedBox(height: 12),
            ],
            AppButton(
              label: 'Escolher outro arquivo',
              variant: AppButtonVariant.secondary,
              icon: Icons.folder_open_outlined,
              expanded: true,
              onPressed: _reiniciar,
            ),
          ],
        ),
      ),
    );
  }
}

enum _ImportStep { selecao, previa, importando, sucesso, erro }
