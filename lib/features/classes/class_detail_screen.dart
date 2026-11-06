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
  });

  final String classId;
  final String className;

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> {
  final ClassRepository _repository = ClassRepository();
  late final Stream<List<StudentRecord>> _studentsStream;
  bool _addingStudent = false;

  @override
  void initState() {
    super.initState();
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

  void _openImportStudents(List<StudentRecord> currentStudents) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImportacaoAlunosScreen(
          nomeTurma: widget.className,
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
        title: Text(widget.className, style: const TextStyle(fontWeight: FontWeight.bold)),
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
  const _AddStudentDialog();

  @override
  State<_AddStudentDialog> createState() => _AddStudentDialogState();
}

class _AddStudentDialogState extends State<_AddStudentDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _matriculaController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String? _errorText;

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
      title: const Text('Adicionar aluno'),
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
        FilledButton(onPressed: _addStudent, child: const Text('Adicionar')),
      ],
    );
  }
}
