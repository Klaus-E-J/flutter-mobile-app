import 'package:flutter/material.dart';

import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import 'data/class_repository.dart';

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
    final studentName = await showDialog<String>(
      context: context,
      builder: (_) => const _AddStudentDialog(),
    );
    if (!mounted || studentName == null) return;

    setState(() => _addingStudent = true);
    try {
      await _repository.addStudent(classId: widget.classId, name: studentName);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível cadastrar o aluno: $error')),
      );
    } finally {
      if (mounted) setState(() => _addingStudent = false);
    }
  }

  void _showImportNotAvailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('A importação por arquivo ainda não está conectada ao Firestore. Nenhum aluno foi importado.'),
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
                  onPressed: _showImportNotAvailable,
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
                          Text('Aluno cadastrado', style: Theme.of(context).textTheme.bodySmall),
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
  final TextEditingController _controller = TextEditingController();
  String? _errorText;

  void _addStudent() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _errorText = 'Digite o nome do aluno');
      return;
    }
    Navigator.pop(context, name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionar aluno'),
      content: AppTextField(
        label: 'Nome',
        hint: 'Nome do aluno',
        controller: _controller,
        errorText: _errorText,
        onChanged: (_) {
          if (_errorText != null) setState(() => _errorText = null);
        },
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: _addStudent, child: const Text('Adicionar')),
      ],
    );
  }
}
