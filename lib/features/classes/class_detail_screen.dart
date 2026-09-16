import 'package:flutter/material.dart';

import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../classes/importacao_alunos_screen.dart';

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
    // Usar sempre o tamanho real da lista mockada
    _studentCount = _students.length;
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

  Future<void> _abrirImportacao() async {
    final importou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ImportacaoAlunosScreen(
          nomeTurma: widget.className,
        ),
      ),
    );

    if (!mounted || importou != true) return;

    // Simula adição dos alunos importados
    setState(() {
      _students.addAll([
        'Adriana Ferreira',
        'Bruno Henrique',
        'Camila Souza',
        'Daniel Ribeiro',
        'Eduarda Lima',
      ]);
      _studentCount = _students.length;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Alunos importados com sucesso.')),
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
            AppButton(
              label: 'Adicionar aluno',
              icon: Icons.add,
              variant: AppButtonVariant.secondary,
              expanded: true,
              onPressed: _showAddStudentDialog,
            ),
            const SizedBox(height: 10),
            AppButton(
              label: 'Importar lista',
              icon: Icons.upload_file_outlined,
              variant: AppButtonVariant.text,
              expanded: true,
              onPressed: _abrirImportacao,
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
