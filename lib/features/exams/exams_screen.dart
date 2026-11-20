import 'package:flutter/material.dart';

import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_error_state.dart';
import '../../core/widgets/app_loading.dart';
import '../../core/widgets/app_status_pill.dart';
import '../../screens/provas/prova_questoes_screen.dart';
import 'data/exam_repository.dart';
import 'exam_form_screen.dart';
import 'exam_print_screen.dart';
import '../../core/theme/app_icons.dart';
import '../../core/widgets/app_snack_bar.dart';
import '../../core/widgets/app_dialog.dart';

class ExamsScreen extends StatefulWidget {
  const ExamsScreen({super.key});

  @override
  State<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen> {
  final ExamRepository _repository = ExamRepository();
  late Stream<List<ExamRecord>> _examsStream;

  @override
  void initState() {
    super.initState();
    _examsStream = _repository.watchExams();
  }

  void _openExam(ExamRecord exam) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExamFormScreen(
          initialExamId: exam.id,
          initialName: exam.title,
          initialClassIds: exam.classIds,
          initialClasses: exam.classNames,
          initialApplicationMode: exam.applicationMode,
        ),
      ),
    );
  }

  void _openQuestions(ExamRecord exam) {
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

  void _openPrint(ExamRecord exam) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExamPrintScreen(
          examId: exam.id,
          examTitle: exam.title,
          classIds: exam.classIds,
          classNames: exam.classNames,
          applicationMode: exam.applicationMode,
        ),
      ),
    );
  }

  void _openCreateExam() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ExamFormScreen()),
    );
  }

  Future<void> _confirmDeleteExam(ExamRecord exam) async {
    final confirmed = await AppDialog.confirm(
      context: context,
      title: 'Excluir prova?',
      message: 'Tem certeza que deseja excluir a prova "${exam.title}", suas questões e variantes?',
      confirmLabel: 'Excluir',
      destructive: true,
    );
    if (!mounted || confirmed != true) return;

    try {
      await _repository.deleteExam(exam.id);
      if (!mounted) return;
      AppSnackBar.success(context, 'Prova excluída com sucesso.');
    } catch (error) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Não foi possível excluir a prova: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Provas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateExam,
        icon: const Icon(AppIcons.add),
        label: const Text('Nova prova'),
      ),
      body: SafeArea(
        child: StreamBuilder<List<ExamRecord>>(
          stream: _examsStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return AppErrorState(
                title: 'Não foi possível carregar as provas',
                description: '${snapshot.error}',
                onRetry: () => setState(
                  () => _examsStream = _repository.watchExams(),
                ),
              );
            }
            if (!snapshot.hasData) return const AppLoading();

            final exams = snapshot.data!;
            if (exams.isEmpty) {
              return const AppEmptyState(
                icon: AppIcons.exams,
                title: 'Nenhuma prova ainda',
                description:
                    'Toque em “Nova prova” para criar uma avaliação e gerar as folhas de resposta.',
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
              itemCount: exams.length + 1,
              separatorBuilder: (_, index) =>
                  SizedBox(height: index == 0 ? 12 : 10),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Text(
                    exams.length == 1 ? '1 prova' : '${exams.length} provas',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  );
                }
                final exam = exams[index - 1];
                return _ExamCard(
                  exam: exam,
                  onTap: () => _openExam(exam),
                  onQuestions: () => _openQuestions(exam),
                  onPrint: () => _openPrint(exam),
                  onDelete: () => _confirmDeleteExam(exam),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

enum _ExamAction { questions, print, delete }

class _ExamCard extends StatelessWidget {
  const _ExamCard({
    required this.exam,
    required this.onTap,
    required this.onQuestions,
    required this.onPrint,
    required this.onDelete,
  });

  final ExamRecord exam;
  final VoidCallback onTap;
  final VoidCallback onQuestions;
  final VoidCallback onPrint;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasQuestions = exam.questionCount > 0;
    final classes = exam.classNames.isEmpty
        ? 'Sem turma vinculada'
        : exam.classNames.join(', ');

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exam.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  classes,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                AppStatusPill(
                  icon: hasQuestions ? AppIcons.questions : AppIcons.warning,
                  label: hasQuestions
                      ? '${exam.questionCount} questões'
                      : 'Sem questões',
                  tone: hasQuestions ? AppStatusTone.neutral : AppStatusTone.warning,
                ),
              ],
            ),
          ),
          PopupMenuButton<_ExamAction>(
            tooltip: 'Mais ações',
            onSelected: (action) => switch (action) {
              _ExamAction.questions => onQuestions(),
              _ExamAction.print => onPrint(),
              _ExamAction.delete => onDelete(),
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: _ExamAction.questions,
                child: ListTile(
                  leading: Icon(AppIcons.questions),
                  title: Text('Questões e gabarito'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: _ExamAction.print,
                child: ListTile(
                  leading: Icon(AppIcons.print),
                  title: Text('Variantes e impressão'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: _ExamAction.delete,
                child: ListTile(
                  leading: Icon(AppIcons.delete, color: colorScheme.error),
                  title: Text(
                    'Excluir prova',
                    style: TextStyle(color: colorScheme.error),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
