import 'package:flutter/material.dart';

import '../../../features/correction/data/submission_repository.dart';
import '../../../features/results/student_result_screen.dart';
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
    this.onSaveSubmissions,
  });

  final ProvaCorrecao prova;
  final List<ResultadoAluno> resultados;
  final int totalErros;
  final Future<void> Function(List<SubmissionRecord> records)? onSaveSubmissions;

  @override
  State<ResultadoCorrecaoScreen> createState() =>
      _ResultadoCorrecaoScreenState();
}

class _ResultadoCorrecaoScreenState extends State<ResultadoCorrecaoScreen> {
  bool _saving = false;
  bool _saved = false;
  Future<bool>? _ongoingSave;

  @override
  void initState() {
    super.initState();
    if (widget.resultados.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _garantirSalvo(showFeedback: false, ignoreErrors: true);
        }
      });
    } else {
      _saved = true;
    }
  }

  List<SubmissionRecord> _buildRecords() {
    return List<SubmissionRecord>.generate(widget.resultados.length, (idx) {
      final r = widget.resultados[idx];
      final safeStudentKey = (r.studentId != null && r.studentId!.isNotEmpty)
          ? r.studentId!
          : 'idx_${idx + 1}_${r.nomeAluno.hashCode.abs()}';
      final deterministicId = (r.submissionId != null && r.submissionId!.isNotEmpty)
          ? r.submissionId!
          : 'sub_${widget.prova.id}_$safeStudentKey';

      return SubmissionRecord(
        id: deterministicId,
        examId: widget.prova.id,
        examTitle: widget.prova.titulo,
        classId: widget.prova.classId ?? '',
        className: widget.prova.turma,
        studentId: r.studentId ?? '',
        studentName: r.nomeAluno,
        score: r.acertos,
        totalQuestions: r.totalQuestoes,
        percentage: r.percentual,
        variantId: r.variantId,
        variantCode: r.variantCode,
        blankCount: r.emBranco,
        invalidCount: r.invalidas,
        finalGrade: r.nota10,
        answers: r.answers ?? [],
      );
    });
  }

  Future<bool> _garantirSalvo({
    bool showFeedback = true,
    bool ignoreErrors = false,
  }) async {
    if (_saved) return true;
    if (_ongoingSave != null) return _ongoingSave!;

    final future = _executarSalvamento(
      showFeedback: showFeedback,
      ignoreErrors: ignoreErrors,
    );
    _ongoingSave = future;
    final ok = await future;
    _ongoingSave = null;
    return ok;
  }

  Future<bool> _executarSalvamento({
    required bool showFeedback,
    required bool ignoreErrors,
  }) async {
    if (_saved) return true;
    if (mounted) setState(() => _saving = true);

    try {
      final records = _buildRecords();
      if (widget.onSaveSubmissions != null) {
        await widget.onSaveSubmissions!(records);
      } else {
        await SubmissionRepository().saveSubmissions(records);
      }

      if (!mounted) {
        _saved = true;
        return true;
      }

      setState(() {
        _saved = true;
        _saving = false;
      });

      if (showFeedback) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${records.length} resultado(s) gravado(s) no Firebase com sucesso!',
            ),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
      }
      return true;
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        if (!ignoreErrors) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Não foi possível salvar os resultados: $error'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
      return false;
    }
  }

  Future<void> _abrirAtalho(BuildContext context, String routeName) async {
    await _garantirSalvo(showFeedback: false, ignoreErrors: true);
    if (!context.mounted) return;
    await Navigator.of(context).pushNamed(routeName);
  }

  Future<void> _concluir(BuildContext context) async {
    if (_saving) {
      await _ongoingSave;
    }
    final jaEstavaSalvo = _saved;
    final ok = await _garantirSalvo(showFeedback: !jaEstavaSalvo);
    if (!context.mounted) return;

    if (jaEstavaSalvo && ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${widget.resultados.length} resultado(s) gravado(s) no Firebase com sucesso!',
          ),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );
    }

    if (ok) {
      Navigator.of(context).popUntil(
        (route) => route.settings.name == '/dashboard' || route.isFirst,
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
                        final item = widget.resultados[index];
                        return _ResultadoAlunoCard(
                          resultado: item,
                          posicao: index + 1,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => StudentResultScreen(
                                  prova: widget.prova,
                                  resultado: item,
                                ),
                              ),
                            );
                          },
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
                        onPressed: _saving
                            ? null
                            : () => _abrirAtalho(context, '/statistics'),
                        icon: const Icon(Icons.bar_chart_outlined),
                        label: const Text('Estatísticas'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _saving
                            ? null
                            : () => _abrirAtalho(context, '/export'),
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
    this.onTap,
  });

  final ResultadoAluno resultado;
  final int posicao;
  final VoidCallback? onTap;

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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
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
      ),
    );
  }
}
