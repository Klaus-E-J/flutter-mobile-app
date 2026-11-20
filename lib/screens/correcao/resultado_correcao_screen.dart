import 'package:flutter/material.dart';

import '../../../core/navigation/app_tabs.dart';
import '../../../core/routes/app_routes.dart';
import '../../../features/correction/data/submission_repository.dart';
import '../../../features/results/student_result_screen.dart';
import 'models/correcao_models.dart';
import '../../core/theme/app_icons.dart';
import '../../core/widgets/app_snack_bar.dart';

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
    this.loadExistingGrades,
  });

  final ProvaCorrecao prova;
  final List<ResultadoAluno> resultados;
  final int totalErros;
  final Future<void> Function(List<SubmissionRecord> records)? onSaveSubmissions;

  /// Notas já salvas da prova (ID da submissão -> nota). Injetável em testes.
  final Future<Map<String, double>> Function(String examId)? loadExistingGrades;

  @override
  State<ResultadoCorrecaoScreen> createState() =>
      _ResultadoCorrecaoScreenState();
}

class _ResultadoCorrecaoScreenState extends State<ResultadoCorrecaoScreen> {
  bool _saving = false;
  bool _saved = false;
  Future<bool>? _ongoingSave;

  /// IDs das submissões desta tela já gravadas.
  final Set<String> _idsSalvos = <String>{};

  /// Alunos que já tinham nota salva e aguardam a decisão do professor.
  List<String> _conflitosPendentes = const [];

  @override
  void initState() {
    super.initState();
    if (widget.resultados.isNotEmpty) {
      // Salva logo as notas novas (proteção contra perda), mas nunca
      // sobrescreve uma nota já salva sem perguntar.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _garantirSalvo(showFeedback: false, ignoreErrors: true, interactive: false);
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
    bool interactive = true,
  }) async {
    if (_saved) return true;
    if (_ongoingSave != null) {
      await _ongoingSave;
      if (_saved || !interactive) return _saved;
    }

    final future = _executarSalvamento(
      showFeedback: showFeedback,
      ignoreErrors: ignoreErrors,
      interactive: interactive,
    );
    _ongoingSave = future;
    final ok = await future;
    _ongoingSave = null;
    return ok;
  }

  /// Notas já salvas desta prova (ID da submissão -> nota 0–10).
  Future<Map<String, double>> _carregarNotasSalvas() async {
    if (widget.loadExistingGrades != null) {
      return widget.loadExistingGrades!(widget.prova.id);
    }
    // Nos testes que injetam o salvamento, não há banco para consultar.
    if (widget.onSaveSubmissions != null) return const {};
    final salvas = await SubmissionRepository().getSubmissionsByExam(widget.prova.id);
    return {
      for (final s in salvas)
        s.id: s.finalGrade ??
            (s.totalQuestions > 0 ? s.score / s.totalQuestions * 10 : 0),
    };
  }

  /// Salva os resultados. Notas novas são salvas direto; um aluno que já
  /// tem nota salva nesta prova só é sobrescrito com a confirmação do
  /// professor ([interactive]). Sem confirmação, a decisão fica pendente.
  Future<bool> _executarSalvamento({
    required bool showFeedback,
    required bool ignoreErrors,
    required bool interactive,
  }) async {
    if (_saved) return true;
    if (mounted) setState(() => _saving = true);

    try {
      final records = _buildRecords();
      final notasSalvas = await _carregarNotasSalvas();
      final pendentes = records.where((r) => !_idsSalvos.contains(r.id)).toList();
      final novos = pendentes.where((r) => !notasSalvas.containsKey(r.id)).toList();
      final conflitos = pendentes.where((r) => notasSalvas.containsKey(r.id)).toList();

      var aSalvar = novos;
      var mantidas = 0;
      var concluido = true;
      if (conflitos.isNotEmpty) {
        if (!interactive) {
          concluido = false;
        } else {
          if (mounted) setState(() => _saving = false);
          final substituir = await _perguntarSubstituicao(conflitos, notasSalvas);
          if (substituir == null) return false; // professor cancelou
          if (mounted) setState(() => _saving = true);
          if (substituir) {
            aSalvar = [...novos, ...conflitos];
          } else {
            mantidas = conflitos.length;
          }
        }
      }

      if (aSalvar.isNotEmpty) {
        if (widget.onSaveSubmissions != null) {
          await widget.onSaveSubmissions!(aSalvar);
        } else {
          await SubmissionRepository().saveSubmissions(aSalvar);
        }
      }
      _idsSalvos.addAll(aSalvar.map((r) => r.id));

      if (!mounted) {
        _saved = concluido;
        return concluido;
      }

      setState(() {
        _saved = concluido;
        _saving = false;
        _conflitosPendentes = concluido
            ? const []
            : conflitos.map((r) => r.studentName).toList();
      });

      if (showFeedback && concluido) {
        final partes = [
          '${aSalvar.length} resultado(s) gravado(s) com sucesso',
          if (mantidas > 0) '$mantidas nota(s) anterior(es) mantida(s)',
        ];
        AppSnackBar.success(context, '${partes.join('; ')}.');
      }
      return concluido;
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        if (!ignoreErrors) {
          AppSnackBar.error(context, 'Não foi possível salvar os resultados: $error');
        }
      }
      return false;
    }
  }

  /// `true` = substituir, `false` = manter as notas salvas, `null` = cancelar.
  Future<bool?> _perguntarSubstituicao(
    List<SubmissionRecord> conflitos,
    Map<String, double> notasSalvas,
  ) {
    final linhas = conflitos.map((r) {
      final antiga = notasSalvas[r.id] ?? 0;
      final nova = r.finalGrade ?? 0;
      return '• ${r.studentName}: nota salva ${antiga.toStringAsFixed(1)} → nova ${nova.toStringAsFixed(1)}';
    }).join('\n');

    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Substituir notas já salvas?'),
        content: SingleChildScrollView(
          child: Text(
            '${conflitos.length} aluno(s) já tinham nota salva nesta prova:\n\n$linhas',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Manter notas salvas'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Substituir'),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirAtalho(BuildContext context, String routeName) async {
    final ok = await _garantirSalvo(showFeedback: false);
    if (!ok || !context.mounted) return;
    await Navigator.of(context).pushNamed(routeName);
  }

  Future<void> _concluir(BuildContext context) async {
    final jaEstavaSalvo = _saved;
    final ok = await _garantirSalvo(showFeedback: !jaEstavaSalvo);
    if (!context.mounted) return;

    if (jaEstavaSalvo && ok) {
      AppSnackBar.success(context, '${widget.resultados.length} resultado(s) gravado(s) com sucesso!');
    }

    // Volta ao app já na aba Resultados, onde a correção recém-salva aparece.
    if (ok) AppTabs.go(context, AppTab.results);
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
        ),
        body: Column(
          children: [
            _buildResumo(theme),
            if (_conflitosPendentes.isNotEmpty && !_saved)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_conflitosPendentes.length} aluno(s) já tinham nota salva nesta prova '
                    '(${_conflitosPendentes.join(', ')}). Toque em “Concluir Correção” '
                    'para decidir se a nota será substituída.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onTertiaryContainer,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'Detalhamento por aluno',
                    style: theme.textTheme.titleMedium,
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
                            : () => _abrirAtalho(context, AppRoutes.statistics),
                        icon: const Icon(AppIcons.statistics),
                        label: const Text('Estatísticas'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _saving
                            ? null
                            : () => _abrirAtalho(context, AppRoutes.export),
                        icon: const Icon(AppIcons.export),
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
                        : const Icon(AppIcons.confirm),
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
            style: theme.textTheme.titleMedium,
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
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
