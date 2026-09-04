import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/widgets/app_card.dart';

class ExamsScreen extends StatelessWidget {
  const ExamsScreen({super.key});

  static const List<ExamData> _exams = [
    ExamData(
      title: 'Avaliação Matemática',
      questionCount: 20,
      studentCount: 28,
    ),
    ExamData(
      title: 'Português — Unidade 2',
      questionCount: 15,
      studentCount: 24,
    ),
    ExamData(
      title: 'Ciências — Bimestre 1',
      questionCount: 25,
      studentCount: 31,
    ),
  ];

  void _openExam(BuildContext context, ExamData exam) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ExamDetailPlaceholder(exam: exam),
      ),
    );
  }

  void _openCreateExamPlaceholder(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const _CreateExamPlaceholder(),
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
                onPressed: () => _openCreateExamPlaceholder(context),
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
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
              // Tela atual.
              break;
            case 3:
              Navigator.pushReplacementNamed(context, AppRoutes.correction);
              break;
            case 4:
              // "Mais" será implementado posteriormente.
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
  });

  final String title;
  final int questionCount;
  final int studentCount;
}

class _ExamDetailPlaceholder extends StatelessWidget {
  const _ExamDetailPlaceholder({required this.exam});

  final ExamData exam;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes da prova')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: AppCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exam.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${exam.questionCount} questões • '
                  '${exam.studentCount} alunos',
                ),
                const SizedBox(height: 16),
                Text(
                  'Tela de detalhes será implementada em outra tarefa.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateExamPlaceholder extends StatelessWidget {
  const _CreateExamPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova prova')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'A tela de Criar/Editar Prova será implementada na FE-06b.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}
