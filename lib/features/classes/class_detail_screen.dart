import 'package:flutter/material.dart';

import '../../core/widgets/app_card.dart';
import '../../screens/import/import_students_sheet.dart';

class ClassDetailScreen extends StatefulWidget {
  const ClassDetailScreen({
    super.key,
    required this.className,
    required this.initialStudentCount,
  });

  final String className;
  final int initialStudentCount;

  @override
  State<ClassDetailScreen> createState() {
    return _ClassDetailScreenState();
  }
}

class _ClassDetailScreenState extends State<ClassDetailScreen> {
  final List<String> _students = [
    'Ana Silva',
    'Bruno Costa',
    'Carla Mendes',
    'Diego Souza',
    'Elisa Rocha',
  ];

  late int _studentCount;

  @override
  void initState() {
    super.initState();
    _studentCount = widget.initialStudentCount;
  }

  Future<void> _showAddStudentDialog() async {
    final studentName = await showDialog<String>(
      context: context,
      builder: (_) => const _AddStudentDialog(),
    );

    if (!mounted || studentName == null) {
      return;
    }

    setState(() {
      _students.add(studentName);
      _studentCount++;
    });
  }

  Future<void> _handleImport() async {
    final importedNames = await showImportStudentsSheet(context);

    if (!mounted || importedNames == null || importedNames.isEmpty) {
      return;
    }

    setState(() {
      _students.addAll(importedNames);
      _studentCount += importedNames.length;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${importedNames.length} alunos importados com sucesso.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.className,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Alunos',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '$_studentCount alunos',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showAddStudentDialog,
                icon: const Icon(Icons.add),
                label: const Text('Adicionar aluno'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _handleImport,
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('Importar lista'),
              ),
            ),
            const SizedBox(height: 8),
            for (final student in _students) ...[
              AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Aluno cadastrado',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddStudentDialog extends StatefulWidget {
  const _AddStudentDialog();

  @override
  State<_AddStudentDialog> createState() {
    return _AddStudentDialogState();
  }
}

class _AddStudentDialogState extends State<_AddStudentDialog> {
  final TextEditingController _controller = TextEditingController();

  String? _errorText;

  void _addStudent() {
    final name = _controller.text.trim();

    if (name.isEmpty) {
      setState(() {
        _errorText = 'Digite o nome do aluno';
      });

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
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          labelText: 'Nome',
          hintText: 'Nome do aluno',
          errorText: _errorText,
        ),
        onChanged: (_) {
          if (_errorText != null) {
            setState(() {
              _errorText = null;
            });
          }
        },
        onSubmitted: (_) => _addStudent(),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _addStudent, child: const Text('Adicionar')),
      ],
    );
  }
}
