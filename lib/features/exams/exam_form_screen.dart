import 'package:flutter/material.dart';
import '../../screens/provas/prova_questoes_screen.dart';
import '../classes/data/class_repository.dart';
import 'data/exam_repository.dart';
import 'exam_print_screen.dart';
import 'models/exam_application_mode.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_loading.dart';
import '../../core/widgets/app_section_header.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/theme/app_icons.dart';
import '../../core/widgets/app_delete_button.dart';
import '../../core/widgets/app_snack_bar.dart';
import '../../core/widgets/app_dialog.dart';

/// Cadastro e edição de provas com persistência no Cloud Firestore.
class ExamFormScreen extends StatefulWidget {
  const ExamFormScreen({
    super.key,
    this.initialExamId,
    this.initialName,
    this.initialClassIds = const <String>[],
    this.initialClasses = const <String>[],
    this.initialApplicationMode = ExamApplicationMode.sameForEveryone,
  });

  /// ID do documento quando a tela está editando uma prova existente.
  final String? initialExamId;

  final String? initialName;
  final List<String> initialClassIds;

  /// Turmas previamente vinculadas no modo de edição.
  final List<String> initialClasses;

  /// Como a prova é aplicada (o que muda de um aluno para outro).
  final ExamApplicationMode initialApplicationMode;

  @override
  State<ExamFormScreen> createState() => _ExamFormScreenState();
}

class _ExamFormScreenState extends State<ExamFormScreen> {
  final ClassRepository _classRepository = ClassRepository();
  final ExamRepository _examRepository = ExamRepository();

  late final TextEditingController _nameController;
  final Set<String> _selectedClassIds = <String>{};
  late ExamApplicationMode _applicationMode;
  List<ClassRecord> _availableClasses = <ClassRecord>[];
  String? _examId;
  bool _loadingClasses = true;
  bool _saving = false;

  String? _nameError;
  String? _classesError;

  bool get _isEditing => _examId != null;

  @override
  void initState() {
    super.initState();
    _examId = widget.initialExamId;
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _selectedClassIds.addAll(widget.initialClassIds);
    _applicationMode = widget.initialApplicationMode;
    _loadClasses();
  }

  /// Avisa quando um modo "por aluno" foi escolhido, mas as turmas estão vazias.
  bool get _showNoStudentsHint {
    if (!_applicationMode.perStudent || _loadingClasses) return false;
    final selected = _availableClasses.where((c) => _selectedClassIds.contains(c.id));
    return selected.isNotEmpty && selected.every((c) => c.studentCount == 0);
  }

  Future<void> _loadClasses() async {
    try {
      final classes = await _classRepository.getClasses();
      if (!mounted) return;
      setState(() {
        _availableClasses = classes;
        final availableIds = classes.map((item) => item.id).toSet();
        _selectedClassIds.retainAll(availableIds);
        if (widget.initialClassIds.isEmpty && widget.initialClasses.isNotEmpty) {
          _selectedClassIds.addAll(
            classes.where((item) => widget.initialClasses.contains(item.name)).map((item) => item.id),
          );
        }
        _loadingClasses = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadingClasses = false);
      AppSnackBar.error(context, 'Não foi possível carregar as turmas: $error');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _toggleClass(String className, bool selected) {
    setState(() {
      if (selected) {
        _selectedClassIds.add(className);
      } else {
        _selectedClassIds.remove(className);
      }

      if (_selectedClassIds.isNotEmpty) {
        _classesError = null;
      }
    });
  }

  Future<void> _openQuestions({bool openQuickAnswerKey = false}) async {
    if (!await _saveExam(showFeedback: false)) return;
    final examId = _examId;
    if (examId == null || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProvaQuestoesScreen(
          examId: examId,
          provaTitulo: _nameController.text.trim(),
          openQuickAnswerKeyOnStart: openQuickAnswerKey,
        ),
      ),
    );
  }

  Future<void> _openPrintAndVariants() async {
    if (!await _saveExam(showFeedback: false)) return;
    final examId = _examId;
    if (examId == null || !mounted) return;
    final selectedClasses = _availableClasses
        .where((item) => _selectedClassIds.contains(item.id))
        .toList();

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ExamPrintScreen(
          examId: examId,
          examTitle: _nameController.text.trim(),
          classIds: selectedClasses.map((item) => item.id).toList(),
          classNames: selectedClasses.map((item) => item.name).toList(),
          applicationMode: _applicationMode,
        ),
      ),
    );
  }

  Future<void> _confirmDeleteExam() async {
    final examId = _examId;
    if (examId == null) return;
    final confirmed = await AppDialog.confirm(
      context: context,
      title: 'Excluir prova?',
      message: 'Tem certeza que deseja excluir a prova "${_nameController.text.trim()}", suas questões e variantes?',
      confirmLabel: 'Excluir',
      destructive: true,
    );
    if (!mounted || confirmed != true) return;

    setState(() => _saving = true);
    try {
      await _examRepository.deleteExam(examId);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Não foi possível excluir a prova: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _saveExam({bool showFeedback = true}) async {
    final title = _nameController.text.trim();
    final hasName = title.isNotEmpty;
    final hasClass = _selectedClassIds.isNotEmpty;
    setState(() {
      _nameError = hasName ? null : 'Informe o nome da prova.';
      _classesError = hasClass ? null : 'Selecione pelo menos uma turma.';
    });
    if (!hasName || !hasClass) return false;

    FocusScope.of(context).unfocus();
    final wasEditing = _examId != null;
    setState(() => _saving = true);
    try {
      final selectedClasses = _availableClasses
          .where((item) => _selectedClassIds.contains(item.id))
          .toList();
      _examId = await _examRepository.saveExam(
        id: _examId,
        title: title,
        classIds: selectedClasses.map((item) => item.id).toList(),
        classNames: selectedClasses.map((item) => item.name).toList(),
        applicationMode: _applicationMode,
      );
      if (wasEditing && _examId != null) {
        try {
          await _examRepository.regenerateVariantsForExam(examId: _examId!);
        } catch (_) {}
      }
      if (!mounted) return true;
      if (showFeedback) {
        AppSnackBar.success(context, wasEditing ? 'Prova salva no Firestore.' : 'Prova criada no Firestore.');
      }
      setState(() {});
      return true;
    } catch (error) {
      if (mounted) {
        AppSnackBar.error(context, 'Não foi possível salvar a prova: $error');
      }
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar prova' : 'Criar prova'),
        actions: [
          if (_isEditing)
            AppDeleteButton(tooltip: 'Excluir prova', onPressed: _saving ? null : _confirmDeleteExam),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: AppButton(
            label: _saving
                ? 'Salvando...'
                : (_isEditing ? 'Salvar alterações' : 'Salvar prova'),
            icon: AppIcons.confirm,
            expanded: true,
            isLoading: _saving,
            onPressed: _loadingClasses ? null : () => _saveExam(),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Defina os dados principais. Questões e impressão ficam nas próximas etapas.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),

              AppTextField(
                label: 'Nome da prova',
                hint: 'Ex.: Avaliação Matemática',
                controller: _nameController,
                errorText: _nameError,
                onChanged: (value) {
                  if (_nameError != null && value.trim().isNotEmpty) {
                    setState(() => _nameError = null);
                  }
                },
              ),
              const SizedBox(height: 28),

              AppSectionHeader(
                title: 'Turmas',
                subtitle: 'Vincule a prova a uma ou mais turmas.',
              ),
              const SizedBox(height: 12),
              if (_loadingClasses)
                const Padding(padding: EdgeInsets.all(16), child: AppLoading())
                else if (_availableClasses.isEmpty)
                  const Text('Cadastre uma turma antes de criar uma prova.')
                  else
                    ..._availableClasses.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AppCard(
                          padding: EdgeInsets.zero,
                          child: CheckboxListTile(
                            value: _selectedClassIds.contains(item.id),
                            onChanged: (value) => _toggleClass(item.id, value ?? false),
                            title: Text(item.name),
                            subtitle: Text(item.grade),
                            controlAffinity: ListTileControlAffinity.trailing,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                          ),
                        ),
                      ),
                    ),
                    if (_classesError != null) ...[
                      const SizedBox(height: 2),
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Text(
                          _classesError!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),

                    AppSectionHeader(
                      title: 'Aplicação da prova',
                      subtitle: 'As questões e alternativas são as mesmas; escolha o que será embaralhado.',
                    ),
                    const SizedBox(height: 12),
                    RadioGroup<ExamApplicationMode>(
                      groupValue: _applicationMode,
                      onChanged: (mode) {
                        if (mode != null) setState(() => _applicationMode = mode);
                      },
                      child: Column(
                        children: [
                          for (final mode in ExamApplicationMode.values) ...[
                            AppCard(
                              padding: EdgeInsets.zero,
                              child: RadioListTile<ExamApplicationMode>(
                                value: mode,
                                title: Text(mode.label),
                                subtitle: Text(mode.description),
                              ),
                            ),
                            if (mode != ExamApplicationMode.values.last)
                              const SizedBox(height: 8),
                          ],
                        ],
                      ),
                    ),
                    if (_showNoStudentsHint) ...[
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(AppIcons.info, size: 18, color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'As turmas selecionadas ainda não têm alunos. Cadastre os alunos '
                              'para gerar a prova embaralhada de cada um.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 28),

                    AppSectionHeader(
                      title: 'Próximas etapas',
                      subtitle: 'A prova é salva automaticamente ao abrir uma etapa.',
                    ),
                    const SizedBox(height: 12),
                    _StepTile(
                      step: 1,
                      icon: AppIcons.questions,
                      title: 'Questões e gabarito',
                      subtitle:
                          'Cadastre as questões ou use o Gabarito Rápido para uma prova externa.',
                      onTap: _saving || _loadingClasses ? null : () => _openQuestions(),
                    ),
                    const SizedBox(height: 10),
                    _StepTile(
                      step: 2,
                      icon: AppIcons.print,
                      title: 'Variantes e impressão',
                      subtitle: 'Gere os cadernos e as folhas de resposta com QR Code.',
                      onTap: _saving || _loadingClasses ? null : _openPrintAndVariants,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Etapa numerada do fluxo da prova (questões → impressão).
class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.step,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final int step;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final enabled = onTap != null;

    return AppCard(
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
              child: Text(
                '$step',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 18, color: colorScheme.primary),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(title, style: theme.textTheme.titleSmall),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(AppIcons.chevron, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
