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

  @override
  void didUpdateWidget(covariant StudentStatsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.className != widget.className) {
      _loadStudents();
    }
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);

    try {
      final students = await widget.repository.getAvailableStudents(
        widget.className,
      );
      if (!mounted) return;

      if (students.isEmpty) {
        setState(() {
          _students = [];
          _selectedStudentId = null;
          _stats = null;
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _students = students;
        _selectedStudentId = students.first.id;
      });

      await _loadStats(students.first.id);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _students = [];
        _selectedStudentId = null;
        _stats = null;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStats(String studentId) async {
    setState(() => _isLoading = true);

    try {
      final stats = await widget.repository.getStudentStats(
        widget.className,
        studentId,
      );
      if (!mounted) return;

      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  /// Retorna o rótulo formatado para exibição no Dropdown.
  /// Caso haja homônimos (alunos com o mesmo nome), adiciona um sufixo
  /// identificador para que o usuário saiba qual aluno está selecionando.
  String _formatStudentLabel(StudentOption student) {
    final duplicates = _students
        .where(
          (s) => s.name.trim().toLowerCase() == student.name.trim().toLowerCase(),
        )
        .toList();

    if (duplicates.length > 1) {
      final index = duplicates.indexWhere((s) => s.id == student.id) + 1;
      final shortId = student.id.length > 4
          ? student.id.substring(0, 4)
          : student.id;
      return '${student.name} (#$index - $shortId)';
    }

    return student.name;
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
        if (_isLoading) ...[
          const LinearProgressIndicator(minHeight: 2),
          const SizedBox(height: 8),
        ],

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
                  child: Text(_formatStudentLabel(student)),
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
