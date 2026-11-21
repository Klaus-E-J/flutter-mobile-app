import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/navigation/app_tabs.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../features/classes/data/class_repository.dart';
import '../../../features/exams/data/exam_repository.dart';
import '../../../features/exams/exam_print_screen.dart';
import '../../../features/exams/models/exam_variant.dart';
import '../provas/models/questao_model.dart';
import '../provas/prova_questoes_screen.dart';
import 'leitura_qr_screen.dart';
import 'models/correcao_models.dart';
import '../../core/theme/app_icons.dart';
import '../../core/widgets/app_snack_bar.dart';

/// Tela inicial do fluxo de correção — Selecionar prova/turma integrada com Firebase.
class SelecaoProvaScreen extends StatefulWidget {
  const SelecaoProvaScreen({super.key});

  @override
  State<SelecaoProvaScreen> createState() => _SelecaoProvaScreenState();
}

class _SelecaoProvaScreenState extends State<SelecaoProvaScreen> {
  final ExamRepository _examRepository = ExamRepository();
  final ClassRepository _classRepository = ClassRepository();

  List<ProvaCorrecao> _provas = [];
  ProvaCorrecao? _provaSelecionada;
  bool _isLoading = true;

  /// Preparando o gabarito para iniciar a leitura (bloqueia toque duplo).
  bool _iniciando = false;

  /// Tempo máximo esperando o servidor antes de usar o que está no aparelho.
  static const Duration _tempoLimite = Duration(seconds: 15);
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _carregarProvas();
    AppTabs.current.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    AppTabs.current.removeListener(_onTabChanged);
    super.dispose();
  }

  /// Ao voltar para a aba Corrigir, atualiza a lista sem piscar a tela.
  void _onTabChanged() {
    if (AppTabs.current.value == AppTab.correction && !_isLoading) {
      _carregarProvas(silent: true);
    }
  }

  Future<void> _carregarProvas({bool silent = false}) async {
    if (!silent || _provas.isEmpty) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final exams = await _examRepository.watchExams().first;
      final classes = await _classRepository.getClasses();
      final classMap = {for (final c in classes) c.id: c};

      final items = <ProvaCorrecao>[];
      for (final exam in exams) {
        if (exam.classIds.isEmpty) {
          items.add(
            ProvaCorrecao(
              id: exam.id,
              titulo: exam.title,
              turma: exam.classNames.isNotEmpty
                  ? exam.classNames.first
                  : 'Sem turma vinculada',
              disciplina: 'Geral',
              totalQuestoes: exam.questionCount,
              totalAlunos: 0,
              modoAplicacao: exam.applicationMode,
            ),
          );
        } else {
          for (int i = 0; i < exam.classIds.length; i++) {
            final classId = exam.classIds[i];
            final className = i < exam.classNames.length
                ? exam.classNames[i]
                : (classMap[classId]?.name ?? 'Turma');
            final classObj = classMap[classId];

            items.add(
              ProvaCorrecao(
                id: exam.id,
                titulo: exam.title,
                turma: className,
                disciplina: classObj?.grade.isNotEmpty == true
                    ? classObj!.grade
                    : 'Avaliação',
                totalQuestoes: exam.questionCount,
                totalAlunos: classObj?.studentCount ?? 0,
                modoAplicacao: exam.applicationMode,
                classId: classId,
              ),
            );
          }
        }
      }

      if (!mounted) return;
      final anterior = _provaSelecionada;
      setState(() {
        _provas = items;
        // Mantém a prova escolhida quando ela continua disponível.
        _provaSelecionada = anterior == null
            ? (items.isNotEmpty ? items.first : null)
            : items.firstWhere(
                (p) => p.id == anterior.id && p.classId == anterior.classId,
                orElse: () => items.first,
              );
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Não foi possível carregar as provas: $error';
      });
    }
  }

  Future<void> _iniciarLeitura() async {
    final prova = _provaSelecionada;
    if (prova == null) return;

    if (prova.totalQuestoes == 0) {
      AppSnackBar.show(context, 'Esta prova não tem questões cadastradas. Cadastre questões antes de iniciar.');
      return;
    }

    if (_iniciando) return; // evita abrir a leitura duas vezes
    setState(() => _iniciando = true);

    List<Questao> questions = [];
    List<StudentRecord> students = [];
    List<ExamVariant> variants = [];
    var usandoDadosDoAparelho = false;

    Future<List<StudentRecord>> carregarAlunos({bool cacheOnly = false}) async {
      if (prova.classId == null || prova.classId!.isEmpty) return const [];
      final lista = await _classRepository.getStudents(prova.classId!, cacheOnly: cacheOnly);
      return lista
          .map((s) => s.withClass(classId: prova.classId, className: prova.turma))
          .toList();
    }

    try {
      try {
        questions = await _examRepository.getQuestions(prova.id).timeout(_tempoLimite);
        students = await carregarAlunos().timeout(_tempoLimite);
        // Sincroniza considerando TODAS as turmas da prova: nunca apaga nem
        // altera as variantes de outras turmas ou de folhas já impressas.
        variants = await _examRepository
            .syncVariants(examId: prova.id, questions: questions)
            .timeout(_tempoLimite);
      } on TimeoutException {
        // Sem resposta do servidor (ex.: sem internet): usa o gabarito que já
        // está salvo no aparelho. Nunca gera um gabarito novo nesse caso.
        usandoDadosDoAparelho = true;
        questions = await _examRepository.getQuestions(prova.id, cacheOnly: true);
        students = await carregarAlunos(cacheOnly: true);
        variants = await _examRepository.getVariants(prova.id, cacheOnly: true);
      }
      if (prova.provaIndividual && students.isNotEmpty) {
        variants = variants
            .where((v) => students.any((s) => s.id == v.studentId))
            .toList();
      }
    } catch (e) {
      debugPrint('Falha ao preparar a correção: $e');
      if (!mounted) return;
      setState(() => _iniciando = false);
      AppSnackBar.error(
        context,
        'Não foi possível carregar o gabarito desta prova. Verifique a conexão e tente novamente.',
      );
      return;
    }

    if (!mounted) return;
    setState(() => _iniciando = false);
    if (questions.isEmpty || variants.isEmpty) {
      AppSnackBar.error(
        context,
        usandoDadosDoAparelho
            ? 'Sem conexão e sem gabarito salvo no aparelho para esta prova. '
                'Conecte-se à internet e tente novamente.'
            : 'Não há gabarito gerado para esta prova/turma. Confira as questões e os alunos da turma.',
      );
      return;
    }
    if (usandoDadosDoAparelho) {
      AppSnackBar.show(
        context,
        'Sem conexão: usando o gabarito salvo no aparelho. As notas serão enviadas quando a internet voltar.',
      );
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LeituraQrScreen(
          prova: prova,
          questions: questions,
          students: students,
          variants: variants,
        ),
      ),
    );
  }

  void _abrirImpressaoPdf() {
    final prova = _provaSelecionada;
    if (prova == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExamPrintScreen(
          examId: prova.id,
          examTitle: prova.titulo,
          classIds: prova.classId != null ? [prova.classId!] : const [],
          classNames: [prova.turma],
          applicationMode: prova.modoAplicacao,
        ),
      ),
    );
  }

  void _abrirQuestoes() {
    final prova = _provaSelecionada;
    if (prova == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProvaQuestoesScreen(
          examId: prova.id,
          provaTitulo: prova.titulo,
        ),
      ),
    ).then((_) => _carregarProvas());
  }


  bool get _podeIniciar =>
      _provaSelecionada != null && _provaSelecionada!.totalQuestoes > 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Corrigir')),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _isLoading
              ? const AppLoading(key: ValueKey('loading'))
              : _errorMessage != null
                  ? AppErrorState(
                      key: const ValueKey('error'),
                      description: _errorMessage,
                      onRetry: _carregarProvas,
                    )
                  : _provas.isEmpty
                      ? AppEmptyState(
                          key: const ValueKey('empty'),
                          icon: AppIcons.correction,
                          title: 'Nenhuma prova para corrigir',
                          description:
                              'Crie uma prova e vincule-a a uma turma para iniciar a correção.',
                          action: FilledButton.icon(
                            onPressed: () => AppTabs.go(context, AppTab.exams),
                            icon: const Icon(AppIcons.exams),
                            label: const Text('Ir para Provas'),
                          ),
                        )
                      : RefreshIndicator(
                          key: const ValueKey('content'),
                          onRefresh: () => _carregarProvas(silent: true),
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                            children: [
                              Text(
                                'Escolha a prova e escaneie as folhas de resposta.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const _EtapasCorrecao(),
                              const SizedBox(height: 20),
                              DropdownButtonFormField<ProvaCorrecao>(
                                // Recria o campo quando a lista é recarregada.
                                key: ObjectKey(_provas),
                                initialValue: _provaSelecionada,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Prova',
                                  prefixIcon: Icon(AppIcons.exams),
                                ),
                                items: _provas.map((prova) {
                                  return DropdownMenuItem(
                                    value: prova,
                                    child: Text(
                                      '${prova.titulo} · ${prova.turma}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() => _provaSelecionada = value);
                                },
                              ),
                              const SizedBox(height: 12),
                              if (_provaSelecionada != null)
                                _ResumoProva(
                                  prova: _provaSelecionada!,
                                  onCadastrarQuestoes: _abrirQuestoes,
                                ),
                              const SizedBox(height: 24),
                              AppButton(
                                label: _iniciando ? 'Preparando gabarito...' : 'Iniciar leitura',
                                icon: AppIcons.correction,
                                expanded: true,
                                isLoading: _iniciando,
                                onPressed: _podeIniciar && !_iniciando ? _iniciarLeitura : null,
                              ),
                              const SizedBox(height: 4),
                              Center(
                                child: TextButton.icon(
                                  onPressed: _podeIniciar ? _abrirImpressaoPdf : null,
                                  icon: const Icon(AppIcons.print, size: 18),
                                  label: const Text('Ainda não imprimiu? Gerar folhas (PDF)'),
                                ),
                              ),
                            ],
                          ),
                        ),
        ),
      ),
    );
  }
}

class _ResumoProva extends StatelessWidget {
  const _ResumoProva({
    required this.prova,
    required this.onCadastrarQuestoes,
  });

  final ProvaCorrecao prova;
  final VoidCallback onCadastrarQuestoes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semQuestoes = prova.totalQuestoes == 0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.classes, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(prova.turma, style: theme.textTheme.titleSmall),
              ),
              if (prova.provaIndividual)
                Tooltip(
                  message: prova.modoAplicacao.label,
                  child: Icon(AppIcons.shuffle, size: 18, color: colorScheme.primary),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${prova.totalAlunos} alunos • ${prova.totalQuestoes} questões',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (semQuestoes) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    AppIcons.warning,
                    size: 18,
                    color: colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta prova ainda não tem questões.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onCadastrarQuestoes,
                    child: const Text('Cadastrar'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Indicador das três etapas do fluxo de correção.
class _EtapasCorrecao extends StatelessWidget {
  const _EtapasCorrecao();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: _Etapa(numero: 1, label: 'Ler QR Code')),
        _EtapaConector(),
        Expanded(child: _Etapa(numero: 2, label: 'Ler respostas')),
        _EtapaConector(),
        Expanded(child: _Etapa(numero: 3, label: 'Revisar notas')),
      ],
    );
  }
}

class _Etapa extends StatelessWidget {
  const _Etapa({required this.numero, required this.label});

  final int numero;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
          child: Text(
            '$numero',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _EtapaConector extends StatelessWidget {
  const _EtapaConector();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: SizedBox(
        width: 24,
        child: Divider(
          thickness: 1.5,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
    );
  }
}
