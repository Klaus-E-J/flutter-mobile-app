import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/widgets/app_card.dart';
import 'exam_form_screen.dart';

/// FE-06 — Lista/Detalhes de Provas
///
/// Ajuste de Front-End para permitir abrir a FE-06b em modo de criação
/// e em modo de edição, usando apenas dados mockados/localmente.
class ExamsScreen extends StatelessWidget {
  const ExamsScreen({super.key});

  static const List<ExamData> _exams = [
    ExamData(
      title: 'Avaliação Matemática',
      questionCount: 20,
      studentCount: 28,
      classes: ['9º Ano A'],
      sameExamForEveryone: true,
    ),
    ExamData(
      title: 'Português — Unidade 2',
      questionCount: 15,
      studentCount: 24,
      classes: ['8º Ano B'],
      sameExamForEveryone: false,
    ),
    ExamData(
      title: 'Ciências — Bimestre 1',
      questionCount: 25,
      studentCount: 31,
      classes: ['Ensino Médio — 1A'],
      sameExamForEveryone: true,
    ),
  ];

  void _openExam(BuildContext context, ExamData exam) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => _ExamDetailScreen(exam: exam),
      ),
    );
  }

  void _openCreateExam(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const ExamFormScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Provas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Minhas provas',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Crie e gerencie suas avaliações',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _openCreateExam(context),
                icon: const Icon(Icons.add),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('Nova prova'),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Provas cadastradas',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            for (final exam in _exams) ...[
              AppCard(
                onTap: () => _openExam(context, exam),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exam.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${exam.questionCount} questões • '
                            '${exam.studentCount} alunos',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurfaceVariant,
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
        selectedIndex: 2,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
              break;
            case 1:
              Navigator.pushReplacementNamed(context, AppRoutes.classes);
              break;
            case 2:
              break;
            case 3:
              Navigator.pushReplacementNamed(context, AppRoutes.correction);
              break;
            case 4:
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
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
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

class ExamData {
  const ExamData({
    required this.title,
    required this.questionCount,
    required this.studentCount,
    required this.classes,
    required this.sameExamForEveryone,
  });

  final String title;
  final int questionCount;
  final int studentCount;
  final List<String> classes;
  final bool sameExamForEveryone;
}

class _ExamDetailScreen extends StatelessWidget {
  const _ExamDetailScreen({required this.exam});

  final ExamData exam;

  void _openEditExam(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ExamFormScreen(
          initialName: exam.title,
          initialClasses: exam.classes,
          initialSameExamForEveryone: exam.sameExamForEveryone,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da prova'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exam.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${exam.questionCount} questões • '
                    '${exam.studentCount} alunos',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Turmas',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(exam.classes.join(', ')),
                  const SizedBox(height: 20),
                  Text(
                    'Modo da prova',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    exam.sameExamForEveryone
                        ? 'Mesma prova para todos (ordem embaralhada)'
                        : 'Provas diferentes por aluno',
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _openEditExam(context),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('Editar prova'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
