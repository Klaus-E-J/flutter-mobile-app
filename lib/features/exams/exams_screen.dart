import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import 'data/exam_repository.dart';
import 'exam_form_screen.dart';

class ExamsScreen extends StatelessWidget {
  const ExamsScreen({super.key});

  static final ExamRepository _repository = ExamRepository();

  void _openExam(BuildContext context, ExamRecord exam) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExamFormScreen(
          initialExamId: exam.id,
          initialName: exam.title,
          initialClassIds: exam.classIds,
          initialClasses: exam.classNames,
          initialSameExamForEveryone: exam.sameExamForEveryone,
        ),
      ),
    );
  }

  void _openCreateExam(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ExamFormScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Provas', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Minhas provas', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Crie e gerencie suas avaliações', style: TextStyle(color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            AppButton(
              label: 'Nova prova',
              icon: Icons.add,
              expanded: true,
              onPressed: () => _openCreateExam(context),
            ),
            const SizedBox(height: 22),
            Text('Provas cadastradas', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            StreamBuilder<List<ExamRecord>>(
              stream: _repository.watchExams(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text('Erro ao carregar provas: ${snapshot.error}'),
                  );
                }
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final exams = snapshot.data!;
                if (exams.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('Nenhuma prova cadastrada. Crie uma prova para começar.'),
                  );
                }
                return Column(
                  children: [
                    for (final exam in exams) ...[
                      AppCard(
                        onTap: () => _openExam(context, exam),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(exam.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${exam.questionCount} questões • ${exam.classNames.length} turmas',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 2,
        onDestinationSelected: (index) {
          switch (index) {
            case 0: Navigator.pushReplacementNamed(context, AppRoutes.dashboard); break;
            case 1: Navigator.pushReplacementNamed(context, AppRoutes.classes); break;
            case 2: break;
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

void _showMaisModal(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mais opções', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.assignment_outlined),
              title: const Text('Resultados'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () { Navigator.pop(ctx); Navigator.pushNamed(context, AppRoutes.results); },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart_outlined),
              title: const Text('Estatísticas'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () { Navigator.pop(ctx); Navigator.pushNamed(context, AppRoutes.statistics); },
            ),
            ListTile(
              leading: const Icon(Icons.upload_outlined),
              title: const Text('Exportar'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () { Navigator.pop(ctx); Navigator.pushNamed(context, AppRoutes.export); },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Configurações'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () { Navigator.pop(ctx); Navigator.pushNamed(context, AppRoutes.config); },
            ),
          ],
        ),
      ),
    ),
  );
}
