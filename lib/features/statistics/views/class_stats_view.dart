import 'package:flutter/material.dart';

import '../data/statistics_repository.dart';
import '../models/statistics_models.dart';
import '../widgets/grade_distribution_chart.dart';
import '../widgets/question_stats_tile.dart';
import '../widgets/stat_card.dart';

/// View "Desempenho da turma" — aba Turma.
///
/// Recebe [className] da tela pai e exibe dropdown de prova,
/// cards de métricas, gráfico de distribuição e questões.
class ClassStatsView extends StatefulWidget {
  const ClassStatsView({
    super.key,
    required this.repository,
    required this.className,
  });

  final StatisticsRepository repository;
  final String className;

  @override
  State<ClassStatsView> createState() => _ClassStatsViewState();
}

class _ClassStatsViewState extends State<ClassStatsView> {
  List<String> _exams = [];
  String? _selectedExam;
  ClassStats? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<void> _loadExams() async {
    final exams = await widget.repository.getAvailableExams(widget.className);
    if (!mounted) return;

    setState(() {
      _exams = exams;
      _selectedExam = exams.isNotEmpty ? exams.first : null;
    });

    if (_selectedExam != null) {
      await _loadStats(_selectedExam!);
    }
  }

  Future<void> _loadStats(String examName) async {
    setState(() => _isLoading = true);

    final stats = await widget.repository.getClassStats(
      widget.className,
      examName,
    );
    if (!mounted) return;

    setState(() {
      _stats = stats;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _stats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final stats = _stats;
    if (stats == null) {
      return const Center(child: Text('Nenhuma prova disponível'));
    }

    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Título
        Text(
          'Desempenho da turma',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${stats.className} • ${stats.examName}',
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),

        const SizedBox(height: 16),

        // Dropdown de prova
        DropdownButtonFormField<String>(
          value: _selectedExam,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.description_outlined),
          ),
          hint: const Text('Selecione a prova'),
          items: _exams.map((exam) {
            return DropdownMenuItem(
              value: exam,
              child: Text(exam),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null && value != _selectedExam) {
              setState(() => _selectedExam = value);
              _loadStats(value);
            }
          },
        ),

        const SizedBox(height: 16),

        // Cards de métricas
        Row(
          children: [
            Expanded(
              child: StatCard(
                value: stats.average.toStringAsFixed(1).replaceAll('.', ','),
                label: 'Média',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatCard(
                value: '${stats.approvalRate.toInt()}%',
                label: 'Aproveitamento',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatCard(
                value: '${stats.totalStudents}',
                label: 'Alunos',
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Distribuição de notas
        Text(
          'Distribuição de notas',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GradeDistributionChart(data: stats.gradeDistribution),

        const SizedBox(height: 24),

        // Alternativas mais marcadas
        Text(
          'Alternativas mais marcadas por questão',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        for (final question in stats.questionStats) ...[
          QuestionStatsTile(stats: question),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
