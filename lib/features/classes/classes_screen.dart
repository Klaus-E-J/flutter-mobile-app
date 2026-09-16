import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import 'class_detail_screen.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  final List<ClassData> _classes = [
    ClassData(name: '9º Ano A', grade: '9º Ano', studentCount: 28),
    ClassData(name: '8º Ano B', grade: '8º Ano', studentCount: 24),
    ClassData(
      name: 'Ensino Médio — 1A',
      grade: '1º Ano do Ensino Médio',
      studentCount: 31,
    ),
  ];

  Future<void> _showCreateClassDialog() async {
    final newClass = await showDialog<ClassData>(
      context: context,
      builder: (_) => const _CreateClassDialog(),
    );

    if (!mounted || newClass == null) {
      return;
    }

    setState(() {
      _classes.add(newClass);
    });
  }

  void _openClass(ClassData selectedClass) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) {
          return ClassDetailScreen(
            className: selectedClass.name,
            initialStudentCount: selectedClass.studentCount,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Turmas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Minhas turmas',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Cadastre e organize seus alunos',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'Nova turma',
              icon: Icons.add,
              expanded: true,
              onPressed: _showCreateClassDialog,
            ),
            const SizedBox(height: 14),
            for (final item in _classes) ...[
              AppCard(
                onTap: () => _openClass(item),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.studentCount} alunos',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: 1,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
              break;
            case 1:
              // Tela atual
              break;
            case 2:
              Navigator.pushReplacementNamed(context, AppRoutes.exams);
              break;
            case 3:
              Navigator.pushReplacementNamed(context, AppRoutes.correction);
              break;
            case 4:
              _showMaisModal(context);
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Turmas',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: 'Provas',
          ),
          NavigationDestination(
            icon: Icon(Icons.adjust_outlined),
            selectedIcon: Icon(Icons.adjust),
            label: 'Corrigir',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz),
            label: 'Mais',
          ),
        ],
      ),
    );
  }
}

class _CreateClassDialog extends StatefulWidget {
  const _CreateClassDialog();

  @override
  State<_CreateClassDialog> createState() {
    return _CreateClassDialogState();
  }
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
          onPressed: () {Navigator.pop(context);},
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _createClass, child: const Text('Criar')),
      ],
    );
  }
}

class ClassData {
  ClassData({
    required this.name,
    required this.grade,
    required this.studentCount,
  });

  final String name;
  final String grade;
  final int studentCount;
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
