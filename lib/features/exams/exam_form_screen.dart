import 'package:flutter/material.dart';
import '../../screens/provas/prova_questoes_screen.dart';
import '../classes/data/class_repository.dart';
import 'data/exam_repository.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';

/// Cadastro e edição de provas com persistência no Cloud Firestore.
class ExamFormScreen extends StatefulWidget {
  const ExamFormScreen({
    super.key,
    this.initialExamId,
    this.initialName,
    this.initialClassIds = const <String>[],
    this.initialClasses = const <String>[],
    this.initialSameExamForEveryone = true,
  });

  /// ID do documento quando a tela está editando uma prova existente.
  final String? initialExamId;

  final String? initialName;
  final List<String> initialClassIds;

  /// Turmas previamente vinculadas no modo de edição.
  final List<String> initialClasses;

  /// true  = mesma prova para todos, com ordem embaralhada.
  /// false = provas diferentes por aluno.
  final bool initialSameExamForEveryone;

  @override
  State<ExamFormScreen> createState() => _ExamFormScreenState();
}

class _ExamFormScreenState extends State<ExamFormScreen> {
  final ClassRepository _classRepository = ClassRepository();
  final ExamRepository _examRepository = ExamRepository();

  late final TextEditingController _nameController;
  final Set<String> _selectedClassIds = <String>{};
  late bool _sameExamForEveryone;
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
    _sameExamForEveryone = widget.initialSameExamForEveryone;
    _loadClasses();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível carregar as turmas: $error')),
      );
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

  Future<void> _openQuestions() async {
    if (!await _saveExam(showFeedback: false)) return;
    final examId = _examId;
    if (examId == null || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProvaQuestoesScreen(
          examId: examId,
          provaTitulo: _nameController.text.trim(),
        ),
      ),
    );
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
        sameExamForEveryone: _sameExamForEveryone,
      );
      if (!mounted) return true;
      if (showFeedback) {
        ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(wasEditing ? 'Prova salva no Firestore.' : 'Prova criada no Firestore.')));
      }
      setState(() {});
      return true;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível salvar a prova: $error')),
        );
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Prova / questões',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isEditing ? 'Editar prova' : 'Nova prova',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Defina os dados principais da avaliação. As questões serão gerenciadas em uma etapa separada.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),

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

              _SectionTitle(
                title: 'Turmas',
                subtitle: 'Vincule a prova a uma ou mais turmas.',
              ),
              const SizedBox(height: 12),
              if (_loadingClasses)
                const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
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

                    _SectionTitle(
                      title: 'Modo da prova',
                      subtitle: 'Escolha como a avaliação será aplicada aos alunos.',
                    ),
                    const SizedBox(height: 12),
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: SwitchListTile.adaptive(
                        value: _sameExamForEveryone,
                        onChanged: (value) {
                          setState(() => _sameExamForEveryone = value);
                        },
                        title: Text(
                          _sameExamForEveryone
                          ? 'Mesma prova para todos'
                        : 'Provas diferentes por aluno',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _sameExamForEveryone
                            ? 'As questões e alternativas poderão ser apresentadas em ordem embaralhada.'
                          : 'Cada aluno receberá uma prova diferente.',
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    _SectionTitle(
                      title: 'Questões',
                      subtitle:
                      'Cadastre e edite as questões que fazem parte desta prova.',
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      label: 'Gerenciar questões',
                      icon: Icons.quiz_outlined,
                      variant: AppButtonVariant.secondary,
                      expanded: true,
                      onPressed: _saving || _loadingClasses ? null : _openQuestions,
                    ),
                    const SizedBox(height: 24),

                    AppButton(
                      label: _saving ? 'Salvando...' : (_isEditing ? 'Salvar alterações' : 'Salvar prova'),
                      icon: Icons.check,
                      expanded: true,
                      onPressed: _saving || _loadingClasses ? null : () => _saveExam(),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}


