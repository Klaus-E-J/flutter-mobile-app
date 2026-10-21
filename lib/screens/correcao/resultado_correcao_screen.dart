import 'package:flutter/material.dart';

import '../../../features/correction/data/submission_repository.dart';
import 'models/correcao_models.dart';

/// Tela de resultados da correção (Step 4 — final).
///
/// Exibe um resumo da correção e a lista individual de alunos.
/// O botão "Concluir Correção" salva os dados no Cloud Firestore.
class ResultadoCorrecaoScreen extends StatefulWidget {
  const ResultadoCorrecaoScreen({
    super.key,
    required this.prova,
    required this.resultados,
    this.totalErros = 0,
  });

  final ProvaCorrecao prova;
  final List<ResultadoAluno> resultados;
  final int totalErros;

  @override
  State<ResultadoCorrecaoScreen> createState() =>
      _ResultadoCorrecaoScreenState();
}

class _ResultadoCorrecaoScreenState extends State<ResultadoCorrecaoScreen> {
  bool _saving = false;

  Future<void> _concluir(BuildContext context) async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final records = widget.resultados.map((r) {
        return SubmissionRecord(
          id: '',
          examId: widget.prova.id,
          examTitle: widget.prova.titulo,
          classId: widget.prova.classId ?? '',
          className: widget.prova.turma,
          studentId: r.studentId ?? '',
          studentName: r.nomeAluno,
          score: r.acertos,
          totalQuestions: r.totalQuestoes,
          percentage: r.percentual,
          answers: r.answers ?? [],
        );
      }).toList();

      await SubmissionRepository().saveSubmissions(records);
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${records.length} resultado(s) gravado(s) no Firebase com sucesso!',
          ),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );

      Navigator.of(context).popUntil(
        (route) => route.settings.name == '/dashboard' || route.isFirst,
      );
    } catch (error) {
      if (!context.mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível salvar os resultados: $error'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_saving) _concluir(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Resultados'),
          automaticallyImplyLeading: false,
          actions: [
            TextButton(
              onPressed: _saving ? null : () => _concluir(context),
              child: Text(_saving ? 'Salvando...' : 'Concluir'),
            ),
          ],
        ),
        body: Column(
          children: [
            _buildResumo(theme),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'Detalhamento por aluno',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${widget.resultados.length} aluno(s)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: widget.resultados.isEmpty
                  ? Center(
                      child: Text(
                        'Nenhuma prova escaneada.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: widget.resultados.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        return _ResultadoAlunoCard(
                          resultado: widget.resultados[index],
                          posicao: index + 1,
                        );
                      },
                    ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            Navigator.of(context).pushNamed('/statistics'),
                        icon: const Icon(Icons.bar_chart_outlined),
                        label: const Text('Estatísticas'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            Navigator.of(context).pushNamed('/export'),
                        icon: const Icon(Icons.upload_outlined),
                        label: const Text('Exportar'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : () => _concluir(context),
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check),
                    label: Text(
                      _saving ? 'Salvando no Firebase...' : 'Concluir Correção',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResumo(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final mediaAcertos = widget.resultados.isEmpty
        ? 0.0
        : widget.resultados.fold<double>(
              0,
              (acc, r) => acc + r.percentual,
            ) /
            widget.resultados.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Text(
            widget.prova.titulo,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            '${widget.prova.turma} · ${widget.prova.disciplina}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildEstatistica(
                theme: theme,
                valor: '${widget.resultados.length}',
                label: 'Corrigidas',
                cor: colorScheme.primary,
              ),
              _buildEstatistica(
                theme: theme,
                valor: '${mediaAcertos.toStringAsFixed(0)}%',
                label: 'Média',
                cor: mediaAcertos >= 60
                    ? colorScheme.primary
                    : colorScheme.error,
              ),
              _buildEstatistica(
                theme: theme,
                valor: '${widget.totalErros}',
                label: 'Erros',
                cor: widget.totalErros > 0
                    ? colorScheme.error
                    : colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEstatistica({
    required ThemeData theme,
    required String valor,
    required String label,
    required Color cor,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            valor,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: cor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultadoAlunoCard extends StatelessWidget {
  const _ResultadoAlunoCard({
    required this.resultado,
    required this.posicao,
  });

  final ResultadoAluno resultado;
  final int posicao;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final aprovado = resultado.percentual >= 60;
    final corNota = aprovado ? colorScheme.primary : colorScheme.error;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(
                '$posicao.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: Text(
                resultado.nomeAluno,
                style: theme.textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  resultado.nota,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
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
          ],
        ),
      ),
    );
  }
}
