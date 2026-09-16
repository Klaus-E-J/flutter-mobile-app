import 'package:flutter/material.dart';
import '../../core/widgets/app_button.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/app_card.dart';
import 'exam_form_screen.dart';

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
        builder: (_) => ExamFormScreen(
          initialName: exam.title,
        ),
      ),
    );
  }

  void _openCreateExamPlaceholder(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ExamFormScreen(),
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
            AppButton(
              label: 'Nova prova',
              icon: Icons.add,
              expanded: true,
              onPressed: () => _openCreateExamPlaceholder(context),
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
