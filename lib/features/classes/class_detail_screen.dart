import 'package:flutter/material.dart';

import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import 'data/class_repository.dart';
import 'importacao_alunos_screen.dart';

class ClassDetailScreen extends StatefulWidget {
  const ClassDetailScreen({
    super.key,
    required this.classId,
    required this.className,
    this.classGrade = '',
  });

  final String classId;
  final String className;
  final String classGrade;

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> {
  final ClassRepository _repository = ClassRepository();
  late final Stream<List<StudentRecord>> _studentsStream;
  bool _addingStudent = false;
  late String _currentClassName;
  late String _currentClassGrade;

  @override
  void initState() {
    super.initState();
    _currentClassName = widget.className;
    _currentClassGrade = widget.classGrade;
    _studentsStream = _repository.watchStudents(widget.classId);
  }

  Future<void> _showAddStudentDialog() async {
    final result = await showDialog<({String name, String matricula, String email})>(
      context: context,
      builder: (_) => const _AddStudentDialog(),
    );
    if (!mounted || result == null) return;

    setState(() => _addingStudent = true);
    try {
      await _repository.addStudent(
        classId: widget.classId,
        name: result.name,
        matricula: result.matricula,
        email: result.email,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível cadastrar o aluno: $error')),
      );
    } finally {
      if (mounted) setState(() => _addingStudent = false);
    }
  }

  Future<void> _showEditStudentDialog(StudentRecord student) async {
    final result = await showDialog<({String name, String matricula, String email})>(
      context: context,
      builder: (_) => _AddStudentDialog(
        initialName: student.name,
        initialMatricula: student.matricula,
        initialEmail: student.email,
        isEditing: true,
      ),
    );
    if (!mounted || result == null) return;

    try {
      await _repository.updateStudent(
        classId: widget.classId,
        studentId: student.id,
        name: result.name,
        matricula: result.matricula,
        email: result.email,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aluno atualizado com sucesso.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível atualizar o aluno: $error')),
      );
    }
  }

  Future<void> _confirmDeleteStudent(StudentRecord student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover aluno?'),
        content: Text(
          'Tem certeza que deseja remover "${student.name}" desta turma?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;

    try {
      await _repository.deleteStudent(
        classId: widget.classId,
        studentId: student.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aluno removido com sucesso.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível remover o aluno: $error')),
      );
    }
  }

  Future<void> _showEditClassDialog() async {
    final updated = await showDialog<({String name, String grade})>(
      context: context,
      builder: (_) => _EditClassDialog(
        initialName: _currentClassName,
        initialGrade: _currentClassGrade,
      ),
    );

    if (!mounted || updated == null) return;
    try {
      await _repository.updateClass(
        classId: widget.classId,
        name: updated.name,
        grade: updated.grade,
      );
      if (!mounted) return;
      setState(() {
        _currentClassName = updated.name;
        _currentClassGrade = updated.grade;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Turma atualizada com sucesso.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível atualizar a turma: $error')),
      );
    }
  }

  Future<void> _confirmDeleteClass() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir turma?'),
        content: Text(
          'Tem certeza que deseja excluir a turma "$_currentClassName" e todos os seus alunos?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;

    try {
      await _repository.deleteClass(widget.classId);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível excluir a turma: $error')),
      );
    }
  }

  void _openImportStudents(List<StudentRecord> currentStudents) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImportacaoAlunosScreen(
          nomeTurma: _currentClassName,
          classId: widget.classId,
          existingStudents: currentStudents,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentClassName, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar turma',
            onPressed: _showEditClassDialog,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Excluir turma',
            onPressed: _confirmDeleteClass,
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<StudentRecord>>(
          stream: _studentsStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Erro ao carregar alunos: ${snapshot.error}'),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final students = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('Alunos', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${students.length} alunos', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 16),
                AppButton(
                  label: _addingStudent ? 'Cadastrando...' : 'Adicionar aluno',
                  icon: Icons.add,
                  variant: AppButtonVariant.secondary,
                  expanded: true,
                  onPressed: _addingStudent ? null : _showAddStudentDialog,
                ),
                const SizedBox(height: 10),
                AppButton(
                  label: 'Importar lista',
                  icon: Icons.upload_file_outlined,
                  variant: AppButtonVariant.text,
                  expanded: true,
                  onPressed: () => _openImportStudents(students),
                ),
                const SizedBox(height: 8),
                if (students.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('Nenhum aluno cadastrado nesta turma.'),
                  ),
                for (final student in students) ...[
                  AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(student.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                              const SizedBox(height: 2),
                              Text(
                                [
                                  if (student.matricula.isNotEmpty) 'Matrícula: ${student.matricula}',
                                  if (student.email.isNotEmpty) student.email,
                                  if (student.matricula.isEmpty && student.email.isEmpty) 'Aluno cadastrado',
                                ].join(' • '),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          tooltip: 'Editar aluno',
                          onPressed: () => _showEditStudentDialog(student),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          tooltip: 'Remover aluno',
                          onPressed: () => _confirmDeleteStudent(student),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AddStudentDialog extends StatefulWidget {
  const _AddStudentDialog({
    this.initialName = '',
    this.initialMatricula = '',
    this.initialEmail = '',
    this.isEditing = false,
  });

  final String initialName;
  final String initialMatricula;
  final String initialEmail;
  final bool isEditing;

  @override
  State<_AddStudentDialog> createState() => _AddStudentDialogState();
}

class _AddStudentDialogState extends State<_AddStudentDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _matriculaController;
  late final TextEditingController _emailController;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _matriculaController = TextEditingController(text: widget.initialMatricula);
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  void _addStudent() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorText = 'Digite o nome do aluno');
      return;
    }
    Navigator.pop(
      context,
      (
        name: name,
        matricula: _matriculaController.text.trim(),
        email: _emailController.text.trim(),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _matriculaController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEditing ? 'Editar aluno' : 'Adicionar aluno'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              label: 'Nome',
              hint: 'Nome completo do aluno',
              controller: _nameController,
              errorText: _errorText,
              onChanged: (_) {
                if (_errorText != null) setState(() => _errorText = null);
              },
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Matrícula (opcional)',
              hint: 'Ex.: 2026001',
              controller: _matriculaController,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'E-mail (opcional)',
              hint: 'Ex.: aluno@escola.com',
              controller: _emailController,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _addStudent,
          child: Text(widget.isEditing ? 'Salvar' : 'Adicionar'),
        ),
      ],
    );
  }
}

class _EditClassDialog extends StatefulWidget {
  const _EditClassDialog({
    required this.initialName,
    required this.initialGrade,
  });

  final String initialName;
  final String initialGrade;

  @override
  State<_EditClassDialog> createState() => _EditClassDialogState();
}

class _EditClassDialogState extends State<_EditClassDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _gradeController;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _gradeController = TextEditingController(text: widget.initialGrade);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _gradeController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Digite o nome da turma');
      return;
    }
    Navigator.pop(
      context,
      (name: name, grade: _gradeController.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar turma'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            label: 'Nome da turma',
            controller: _nameController,
            errorText: _nameError,
            onChanged: (_) {
              if (_nameError != null) {
                setState(() => _nameError = null);
              }
            },
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Série',
            controller: _gradeController,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
