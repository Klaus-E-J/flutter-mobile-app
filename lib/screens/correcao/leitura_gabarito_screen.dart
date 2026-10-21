import 'package:flutter/material.dart';

import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../features/classes/data/class_repository.dart';
import '../../../features/correction/data/submission_repository.dart';
import '../provas/models/questao_model.dart';
import 'leitura_qr_screen.dart';
import 'models/correcao_models.dart';
import 'resultado_correcao_screen.dart';
import 'widgets/camera_placeholder.dart';

const _nomesMock = [
  'Ana Silva',
  'Bruno Costa',
  'Carla Souza',
  'Diego Oliveira',
  'Elena Santos',
  'Felipe Mendes',
  'Gabriela Lima',
  'Hugo Pereira',
  'Isabela Rocha',
  'João Silva',
  'Karen Almeida',
  'Lucas Ribeiro',
  'Marina Araújo',
  'Nicolas Martins',
  'Olívia Cardoso',
  'Pedro Nascimento',
  'Rafaela Gomes',
  'Samuel Barbosa',
  'Tatiana Moreira',
  'Vinícius Carvalho',
];

/// Tela de leitura dos gabaritos dos alunos (Step 2/2).
class LeituraGabaritoScreen extends StatefulWidget {
  const LeituraGabaritoScreen({
    super.key,
    required this.prova,
    this.questions,
    this.students,
    this.provasLidas = 0,
    this.errosLeitura = 0,
    this.resultadosIniciais = const [],
  });

  final ProvaCorrecao prova;
  final List<Questao>? questions;
  final List<StudentRecord>? students;
  final int provasLidas;
  final int errosLeitura;
  final List<ResultadoAluno> resultadosIniciais;

  @override
  State<LeituraGabaritoScreen> createState() => _LeituraGabaritoScreenState();
}

class _LeituraGabaritoScreenState extends State<LeituraGabaritoScreen> {
  LeituraStatus _status = LeituraStatus.aguardando;
  String? _feedbackText;
  bool _feedbackIsError = false;

  late int _provasLidas;
  late int _errosLeitura;
  late final List<ResultadoAluno> _resultadosCapturados;

  @override
  void initState() {
    super.initState();
    _provasLidas = widget.provasLidas;
    _errosLeitura = widget.errosLeitura;
    _resultadosCapturados = List<ResultadoAluno>.from(widget.resultadosIniciais);
  }

  /// Nome do aluno atual (real da turma ou mock se vazia).
  String get _alunoAtual {
    if (widget.students != null && widget.students!.isNotEmpty) {
      final index = _provasLidas % widget.students!.length;
      return widget.students![index].name;
    }
    final index = _provasLidas % _nomesMock.length;
    return _nomesMock[index];
  }

  String get _alunoIdAtual {
    if (widget.students != null && widget.students!.isNotEmpty) {
      final index = _provasLidas % widget.students!.length;
      return widget.students![index].id;
    }
    return 'simulado_${_provasLidas + 1}';
  }

  /// Simula captura de um gabarito e gera as respostas reais calculadas.
  Future<void> _capturar() async {
    setState(() {
      _status = LeituraStatus.processando;
      _feedbackText = null;
    });

    await Future<void>.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    final nomeCapturado = _alunoAtual;
    final idCapturado = _alunoIdAtual;
    _provasLidas++;

    final answers = <SubmissionQuestionAnswer>[];
    const letters = ['A', 'B', 'C', 'D', 'E'];

    final totalQ = widget.prova.totalQuestoes > 0 ? widget.prova.totalQuestoes : 10;
    final questions = widget.questions;

    for (int i = 0; i < totalQ; i++) {
      String correctLetter = 'A';
      if (questions != null && i < questions.length) {
        final q = questions[i];
        final correctIdx = q.alternativas.indexWhere((a) => a.correta);
        if (correctIdx >= 0 && correctIdx < letters.length) {
          correctLetter = letters[correctIdx];
        }
      } else {
        correctLetter = letters[i % letters.length];
      }

      // Variação realista de acertos: ~80% de chance de acerto
      final seed = (nomeCapturado.hashCode + i * 17).abs();
      final isCorrect = (seed % 10) >= 2; // 80% acerto

      String markedLetter;
      if (isCorrect) {
        markedLetter = correctLetter;
      } else {
        final otherLetters = letters.where((l) => l != correctLetter).toList();
        markedLetter = otherLetters[seed % otherLetters.length];
      }

      answers.add(
        SubmissionQuestionAnswer(
          questionNumber: i + 1,
          marked: markedLetter,
          correct: correctLetter,
          isCorrect: isCorrect,
        ),
      );
    }

    final acertos = answers.where((a) => a.isCorrect).length;
    _resultadosCapturados.add(
      ResultadoAluno(
        studentId: idCapturado,
        nomeAluno: nomeCapturado,
        acertos: acertos,
        totalQuestoes: totalQ,
        answers: answers,
      ),
    );

    setState(() {
      _status = LeituraStatus.sucesso;
      _feedbackText = 'Gabarito de $nomeCapturado registrado';
      _feedbackIsError = false;
    });

    await Future<void>.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    if (widget.prova.provaIndividual) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LeituraQrScreen(
            prova: widget.prova,
            questions: widget.questions,
            students: widget.students,
            provasLidas: _provasLidas,
            errosLeitura: _errosLeitura,
            resultadosAcumulados: _resultadosCapturados,
          ),
        ),
      );
      return;
    }

    setState(() {
      _status = LeituraStatus.aguardando;
      _feedbackText = null;
    });
  }

  /// Simula erro na leitura.
  Future<void> _simularErro() async {
    setState(() {
      _status = LeituraStatus.processando;
      _feedbackText = null;
    });

    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    _errosLeitura++;

    setState(() {
      _status = LeituraStatus.erro;
      _feedbackText =
          'Folha não reconhecida. Reposicione e tente novamente.';
      _feedbackIsError = true;
    });

    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    setState(() {
      _status = LeituraStatus.aguardando;
      _feedbackText = null;
    });
  }

  /// Finaliza a captura e navega para resultados com os dados capturados.
  void _finalizar() {
    final resultados = _resultadosCapturados.isNotEmpty
        ? _resultadosCapturados
        : gerarResultadosMock(
            _provasLidas,
            widget.prova.totalQuestoes,
          );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultadoCorrecaoScreen(
          prova: widget.prova,
          resultados: resultados,
          totalErros: _errosLeitura,
        ),
      ),
    );
  }

  Future<void> _confirmarCancelamento() async {
    final msg = _provasLidas > 0
        ? 'Você já capturou $_provasLidas gabarito(s). '
            'Se sair agora, esse progresso será perdido.'
        : 'Se sair agora, a correção será cancelada.';

    bool? sair;
    await AppDialog.show(
      context: context,
      title: 'Cancelar captura?',
      message: msg,
      confirmLabel: 'Sair',
      cancelLabel: 'Continuar',
      onConfirm: () => sair = true,
    );

    if ((sair ?? false) && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmarCancelamento();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Correção • 2/2'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _confirmarCancelamento,
          ),
          actions: [
            if (_provasLidas > 0)
              TextButton(
                onPressed: _status != LeituraStatus.processando
                    ? _finalizar
                    : null,
                child: const Text('Finalizar'),
              ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  'Ler provas',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Capture cada folha de respostas',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                CameraPlaceholder(
                  label: 'OMR',
                  status: _status,
                  icon: _status == LeituraStatus.aguardando
                      ? Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: Color(0xFF16A34A),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              widget.prova.titulo.isNotEmpty
                                  ? widget.prova.titulo[0].toUpperCase()
                                  : 'K',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  'Prova ${_provasLidas + 1} de ${widget.prova.totalAlunos > 0 ? widget.prova.totalAlunos : (_provasLidas + 1)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Aluno: $_alunoAtual',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                if (_feedbackText != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _feedbackText!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _feedbackIsError
                          ? colorScheme.error
                          : const Color(0xFF16A34A),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const Spacer(),
                AppButton(
                  label: _status == LeituraStatus.processando
                      ? 'Processando...'
                      : 'Capturar prova',
                  icon: _status == LeituraStatus.processando
                      ? null
                      : Icons.document_scanner_outlined,
                  isLoading: _status == LeituraStatus.processando,
                  expanded: true,
                  onPressed:
                      _status == LeituraStatus.aguardando ? _capturar : null,
                ),
                const SizedBox(height: 8),
                if (_status == LeituraStatus.aguardando)
                  Center(
                    child: TextButton(
                      onPressed: _simularErro,
                      child: Text(
                        'Simular erro de leitura',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
