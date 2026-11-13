import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import 'class_detail_screen.dart';
import 'data/class_repository.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  final ClassRepository _repository = ClassRepository();
  late final Stream<List<ClassRecord>> _classesStream;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _classesStream = _repository.watchClasses();
  }

  Future<void> _showCreateClassDialog() async {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível criar a turma: $error')),
      );
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _showEditClassDialog(ClassRecord targetClass) async {
    final updated = await showDialog<ClassData>(
      context: context,
      builder: (_) => _CreateClassDialog(
        initialName: targetClass.name,
        initialGrade: targetClass.grade,
        isEditing: true,
      ),
    );
    if (!mounted || updated == null) return;

    try {
      await _repository.updateClass(
        classId: targetClass.id,
        name: updated.name,
        grade: updated.grade,
      );
      if (!mounted) return;
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

  Future<void> _confirmDeleteClass(ClassRecord targetClass) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir turma?'),
        content: Text(
          'Tem certeza que deseja excluir a turma "${targetClass.name}" e todos os seus alunos cadastrados?',
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
      await _repository.deleteClass(targetClass.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Turma excluída com sucesso.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível excluir a turma: $error')),
      );
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Turmas', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Minhas turmas', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Cadastre e organize seus alunos', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            AppButton(
              label: _creating ? 'Criando turma...' : 'Nova turma',
              icon: Icons.add,
              expanded: true,
              onPressed: _creating ? null : _showCreateClassDialog,
            ),
            const SizedBox(height: 14),
            StreamBuilder<List<ClassRecord>>(
              stream: _classesStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text('Erro ao carregar turmas: ${snapshot.error}'),
                  );
                }
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final classes = snapshot.data!;
                if (classes.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('Nenhuma turma cadastrada. Crie uma turma para começar.'),
                  );
                }
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: classes.length,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 420,
                    mainAxisExtent: 88,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    final item = classes[index];
                    return AppCard(
                      onTap: () => _openClass(item),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  [
                                    if (item.grade.isNotEmpty) item.grade,
                                    '${item.studentCount} alunos',
                                  ].join(' • '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            tooltip: 'Opções da turma',
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showEditClassDialog(item);
                              } else if (value == 'delete') {
                                _confirmDeleteClass(item);
                              }
                            },
                            itemBuilder: (ctx) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: ListTile(
                                  leading: Icon(Icons.edit_outlined),
                                  title: Text('Editar turma'),
                                  contentPadding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                  leading: Icon(Icons.delete_outline, color: Colors.red),
                                  title: Text('Excluir turma', style: TextStyle(color: Colors.red)),
                                  contentPadding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 1,
        onDestinationSelected: (index) {
          switch (index) {
            case 0: Navigator.pushReplacementNamed(context, AppRoutes.dashboard); break;
            case 1: break;
            case 2: Navigator.pushReplacementNamed(context, AppRoutes.exams); break;
            case 3: Navigator.pushReplacementNamed(context, AppRoutes.correction); break;
            case 4: _showMaisModal(context); break;
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Início'),
          NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Turmas'),
          NavigationDestination(icon: Icon(Icons.description_outlined), selectedIcon: Icon(Icons.description), label: 'Provas'),
          NavigationDestination(icon: Icon(Icons.adjust_outlined), selectedIcon: Icon(Icons.adjust), label: 'Corrigir'),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'Mais'),
        ],
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
  const _CreateClassDialog({
    this.initialName = '',
    this.initialGrade = '',
    this.isEditing = false,
  });

  final String initialName;
  final String initialGrade;
  final bool isEditing;

  @override
  State<_CreateClassDialog> createState() {
    return _CreateClassDialogState();
  }
}

class _CreateClassDialogState extends State<_CreateClassDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _gradeController;

  String? _nameError;
  String? _gradeError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _gradeController = TextEditingController(text: widget.initialGrade);
  }

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

    final newClass = ClassData(name: name, grade: grade, studentCount: 0);
    Navigator.pop(context, newClass);
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
      title: Text(widget.isEditing ? 'Editar turma' : 'Nova turma'),
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
          child: Text(widget.isEditing ? 'Salvar' : 'Criar'),
        ),
      ],
    );
  }
}

void _showMaisModal(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mais opções',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.assignment_outlined),
                title: const Text('Resultados'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, AppRoutes.results);
                },
              ),
              ListTile(
                leading: const Icon(Icons.bar_chart_outlined),
                title: const Text('Estatísticas'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, AppRoutes.statistics);
                },
              ),
              ListTile(
                leading: const Icon(Icons.upload_outlined),
                title: const Text('Exportar'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, AppRoutes.export);
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Configurações'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, AppRoutes.config);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
