import 'package:flutter/material.dart';

import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_error_state.dart';
import '../../core/widgets/app_loading.dart';
import '../../core/widgets/app_text_field.dart';
import 'class_detail_screen.dart';
import 'data/class_repository.dart';
import '../../core/theme/app_icons.dart';
import '../../core/widgets/app_snack_bar.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  final ClassRepository _repository = ClassRepository();
  late Stream<List<ClassRecord>> _classesStream;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _classesStream = _repository.watchClasses();
  }

  Future<void> _showCreateClassDialog() async {
    if (_creating) return;
    final newClass = await showDialog<ClassData>(
      context: context,
      builder: (_) => const _CreateClassDialog(),
    );
    if (!mounted || newClass == null) return;

    setState(() => _creating = true);
    try {
      await _repository.createClass(name: newClass.name, grade: newClass.grade);
    } catch (error) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Não foi possível criar a turma: $error');
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  void _openClass(ClassRecord selectedClass) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClassDetailScreen(
          classId: selectedClass.id,
          className: selectedClass.name,
          classGrade: selectedClass.grade,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Turmas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateClassDialog,
        icon: _creating
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(AppIcons.add),
        label: Text(_creating ? 'Criando...' : 'Nova turma'),
      ),
      body: SafeArea(
        child: StreamBuilder<List<ClassRecord>>(
          stream: _classesStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return AppErrorState(
                title: 'Não foi possível carregar as turmas',
                description: '${snapshot.error}',
                onRetry: () => setState(
                  () => _classesStream = _repository.watchClasses(),
                ),
              );
            }
            if (!snapshot.hasData) return const AppLoading();

            final classes = snapshot.data!;
            if (classes.isEmpty) {
              return const AppEmptyState(
                icon: AppIcons.classes,
                title: 'Nenhuma turma ainda',
                description:
                    'Toque em “Nova turma” para cadastrar ou importar seus alunos.',
              );
            }

            return ListView.separated(
              // Espaço extra no fim para o botão flutuante não cobrir o último item.
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
              itemCount: classes.length + 1,
              separatorBuilder: (_, index) =>
                  SizedBox(height: index == 0 ? 12 : 10),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Text(
                    classes.length == 1 ? '1 turma' : '${classes.length} turmas',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  );
                }
                final item = classes[index - 1];
                return AppCard(
                  onTap: () => _openClass(item),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: colorScheme.secondaryContainer,
                        foregroundColor: colorScheme.onSecondaryContainer,
                        child: const Icon(AppIcons.classes, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              [
                                if (item.grade.isNotEmpty) item.grade,
                                item.studentCount == 1
                                    ? '1 aluno'
                                    : '${item.studentCount} alunos',
                              ].join(' • '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class ClassData {
  const ClassData({required this.name, required this.grade, this.studentCount = 0});
  final String name;
  final String grade;
  final int studentCount;
}

class _CreateClassDialog extends StatefulWidget {
  const _CreateClassDialog();

  @override
  State<_CreateClassDialog> createState() => _CreateClassDialogState();
}

class _CreateClassDialogState extends State<_CreateClassDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _gradeController = TextEditingController();

  String? _nameError;
  String? _gradeError;

  void _createClass() {
    final name = _nameController.text.trim();
    final grade = _gradeController.text.trim();

    if (name.isEmpty || grade.isEmpty) {
      setState(() {
        _nameError = name.isEmpty ? 'Digite o nome da turma' : null;
        _gradeError = grade.isEmpty ? 'Digite a série da turma' : null;
      });
      return;
    }

    Navigator.pop(context, ClassData(name: name, grade: grade));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _gradeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nova turma'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            label: 'Nome da turma',
            hint: 'Ex.: 9º Ano A',
            controller: _nameController,
            errorText: _nameError,
            onChanged: (_) {
              if (_nameError != null) setState(() => _nameError = null);
            },
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Série',
            hint: 'Ex.: 9º Ano',
            controller: _gradeController,
            errorText: _gradeError,
            onChanged: (_) {
              if (_gradeError != null) setState(() => _gradeError = null);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _createClass,
          child: const Text('Criar'),
        ),
      ],
    );
  }
}
