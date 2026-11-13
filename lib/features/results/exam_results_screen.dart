import 'package:flutter/material.dart';

import '../../core/widgets/app_card.dart';
import '../../screens/correcao/models/correcao_models.dart';
import '../correction/data/submission_repository.dart';
import 'student_result_screen.dart';

/// FE-10 — Resultados de uma prova.
///
/// Exibe os alunos da prova.
/// Ao clicar em um aluno, abre o resultado individual.
class ExamResultsScreen extends StatefulWidget {
  const ExamResultsScreen({
    super.key,
    required this.prova,
    required this.resultados,
    this.totalErros = 0,
  });

  final ProvaCorrecao prova;
  final List<ResultadoAluno> resultados;
  final int totalErros;

  @override
  State<ExamResultsScreen> createState() => _ExamResultsScreenState();
}

class _ExamResultsScreenState extends State<ExamResultsScreen> {
  final SubmissionRepository _submissionRepository = SubmissionRepository();
  late List<ResultadoAluno> _resultados;

  @override
  void initState() {
    super.initState();
    _resultados = List<ResultadoAluno>.from(widget.resultados);
  }

  Future<void> _confirmDeleteStudentResult(ResultadoAluno resultado) async {
    final submissionId = resultado.submissionId;
    if (submissionId == null || submissionId.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir correção do aluno?'),
        content: Text(
          'Tem certeza que deseja excluir o resultado de "${resultado.nomeAluno}"?',
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
    if (!mounted || confirmed != true) return;

    try {
      await _submissionRepository.deleteSubmission(submissionId);
      if (!mounted) return;
      setState(() {
        _resultados.removeWhere((r) => r.submissionId == submissionId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resultado excluído com sucesso.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível excluir o resultado: $error')),
      );
    }
  }

  Future<void> _confirmDeleteAllResults() async {
    if (_resultados.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir todos os resultados?'),
        content: Text(
          'Tem certeza que deseja excluir todas as ${_resultados.length} correções de "${widget.prova.titulo}"?',
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
            child: const Text('Excluir tudo'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;

    try {
      await _submissionRepository.deleteSubmissionsByExam(
        widget.prova.id,
        classId: widget.prova.classId?.isNotEmpty == true
            ? widget.prova.classId
            : null,
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível excluir os resultados: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final media = _resultados.isEmpty
        ? 0.0
        : _resultados.fold<double>(
                0,
                (sum, resultado) => sum + resultado.percentual,
              ) /
              _resultados.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados da prova'),
        actions: [
          if (_resultados.any((r) => r.submissionId != null))
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Excluir todos os resultados desta prova',
              onPressed: _confirmDeleteAllResults,
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              widget.prova.titulo,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),

            Text(
              '${widget.prova.turma} · ${widget.prova.disciplina}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 20),

            AppCard(
              child: Row(
                children: [
                  Expanded(
                    child: _ResumoItem(
                      valor: '${_resultados.length}',
                      titulo: 'Alunos',
                    ),
                  ),
                  Expanded(
                    child: _ResumoItem(
                      valor: '${media.toStringAsFixed(0)}%',
                      titulo: 'Média',
                    ),
                  ),
                  Expanded(
                    child: _ResumoItem(
                      valor: '${widget.prova.totalQuestoes}',
                      titulo: 'Questões',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Alunos',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              'Selecione um aluno para visualizar o resultado individual.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 12),

            if (_resultados.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'Nenhum resultado disponível.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              for (final resultado in _resultados) ...[
                _AlunoResultadoCard(
                  resultado: resultado,
                  onDelete: resultado.submissionId != null
                      ? () => _confirmDeleteStudentResult(resultado)
                      : null,
                  onTap: () async {
                    final deleted = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute<bool>(
                        builder: (_) => StudentResultScreen(
                          prova: widget.prova,
                          resultado: resultado,
                        ),
                      ),
                    );
                    if (deleted == true && mounted) {
                      setState(() {
                        _resultados.removeWhere(
                          (r) => r.submissionId == resultado.submissionId,
                        );
                      });
                    }
                  },
                ),
                const SizedBox(height: 10),
              ],
          ],
        ),
      ),
    );
  }
}

class _ResumoItem extends StatelessWidget {
  const _ResumoItem({
    required this.valor,
    required this.titulo,
  });

  final String valor;
  final String titulo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          valor,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          titulo,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _AlunoResultadoCard extends StatelessWidget {
  const _AlunoResultadoCard({
    required this.resultado,
    required this.onTap,
    this.onDelete,
  });

  final ResultadoAluno resultado;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final erros =
        resultado.totalQuestoes - resultado.acertos;

    final corNota = resultado.percentual >= 60
        ? colorScheme.primary
        : colorScheme.error;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            child: Text(
              resultado.nomeAluno.isNotEmpty
                  ? resultado.nomeAluno[0]
                  : '?',
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resultado.nomeAluno,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${resultado.acertos} acertos • $erros erros',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                resultado.nota,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: corNota,
                ),
              ),
              Text(
                '${resultado.percentual.toStringAsFixed(0)}%',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),

          if (onDelete != null)
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                size: 20,
                color: colorScheme.error,
              ),
              tooltip: 'Excluir resultado do aluno',
              onPressed: onDelete,
            ),

          Icon(
            Icons.chevron_right,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}