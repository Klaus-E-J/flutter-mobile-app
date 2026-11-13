import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../screens/provas/prova_questoes_screen.dart';
import 'data/exam_repository.dart';
import 'exam_form_screen.dart';
import 'exam_print_screen.dart';

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

  void _openQuestions(BuildContext context, ExamRecord exam) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProvaQuestoesScreen(
          examId: exam.id,
          provaTitulo: exam.title,
        ),
      ),
    );
  }

  void _openPrint(BuildContext context, ExamRecord exam) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExamPrintScreen(
          examId: exam.id,
          examTitle: exam.title,
          classIds: exam.classIds,
          classNames: exam.classNames,
          sameExamForEveryone: exam.sameExamForEveryone,
        ),
      ),
    );
  }

  Future<void> _confirmDeleteExam(BuildContext context, ExamRecord exam) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir prova?'),
        content: Text(
          'Tem certeza que deseja excluir a prova "${exam.title}", suas questões e variantes?',
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
    if (!context.mounted || confirmed != true) return;

    try {
      await _repository.deleteExam(exam.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prova excluída com sucesso.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível excluir a prova: $error')),
      );
    }
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
                            PopupMenuButton<String>(
                              tooltip: 'Opções da prova',
                              onSelected: (value) {
                                switch (value) {
                                  case 'edit':
                                    _openExam(context, exam);
                                    break;
                                  case 'questions':
                                    _openQuestions(context, exam);
                                    break;
                                  case 'print':
                                    _openPrint(context, exam);
                                    break;
                                  case 'delete':
                                    _confirmDeleteExam(context, exam);
                                    break;
                                }
                              },
                              itemBuilder: (ctx) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: ListTile(
                                    leading: Icon(Icons.edit_outlined),
                                    title: Text('Editar prova'),
                                    contentPadding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'questions',
                                  child: ListTile(
                                    leading: Icon(Icons.quiz_outlined),
                                    title: Text('Questões / Gabarito'),
                                    contentPadding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'print',
                                  child: ListTile(
                                    leading: Icon(Icons.picture_as_pdf_outlined),
                                    title: Text('Variantes e Impressão'),
                                    contentPadding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: ListTile(
                                    leading: Icon(Icons.delete_outline, color: Colors.red),
                                    title: Text('Excluir prova', style: TextStyle(color: Colors.red)),
                                    contentPadding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                              ],
                            ),
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
