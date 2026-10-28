import 'package:flutter/material.dart';

import '../data/statistics_repository.dart';
import '../models/statistics_models.dart';
import '../widgets/stat_card.dart';
import '../widgets/subject_history_tile.dart';

/// View "Desempenho do aluno" — aba Aluno.
///
/// Recebe [className] da tela pai e exibe dropdown de aluno,
/// cards de métricas e histórico por disciplina.
class StudentStatsView extends StatefulWidget {
  const StudentStatsView({
    super.key,
    required this.repository,
    required this.className,
  });

  final StatisticsRepository repository;
  final String className;

  @override
  State<StudentStatsView> createState() => _StudentStatsViewState();
}

class _StudentStatsViewState extends State<StudentStatsView> {
  List<StudentOption> _students = [];
  String? _selectedStudentId;
  StudentStats? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    final students = await widget.repository.getAvailableStudents(
      widget.className,
    );
    if (!mounted) return;

    setState(() {
      _students = students;
      _selectedStudentId = students.isNotEmpty ? students.first.id : null;
    });

    if (_selectedStudentId != null) {
      await _loadStats(_selectedStudentId!);
    }
  }

  Future<void> _loadStats(String studentId) async {
    setState(() => _isLoading = true);

    final stats = await widget.repository.getStudentStats(
      widget.className,
      studentId,
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
      return const Center(child: Text('Nenhum aluno disponível'));
    }

    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Dropdown de aluno
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedStudentId,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down),
              items: _students.map((student) {
                return DropdownMenuItem<String>(
                  value: student.id,
                  child: Text(student.name),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null && value != _selectedStudentId) {
                  setState(() => _selectedStudentId = value);
                  _loadStats(value);
                }
              },
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Título
        Text(
          'Desempenho do aluno',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          stats.studentName,
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
          ),
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
                value: '${stats.examCount}',
                label: 'Provas',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatCard(
                value: '${stats.approvalRate.toInt()}%',
                label: 'Aproveitamento',
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Histórico
        Text(
          'Histórico',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        for (final result in stats.subjectResults) ...[
          SubjectHistoryTile(
            result: result,
            // onTap será conectado ao FE-10 (Resultados do aluno) no futuro.
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
