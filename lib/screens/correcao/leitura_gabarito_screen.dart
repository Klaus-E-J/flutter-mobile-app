import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../features/classes/data/class_repository.dart';
import '../../../features/correction/models/omr_layout_spec.dart';
import '../../../features/correction/services/exam_grading_service.dart';
import '../../../features/correction/services/omr_image_service.dart';
import '../../../features/correction/services/sheet_qr_validator.dart';
import '../../../features/exams/models/exam_variant.dart';
import '../../../features/exams/services/exam_randomizer_service.dart';
import '../provas/models/questao_model.dart';
import 'leitura_qr_screen.dart';
import 'models/correcao_models.dart';
import 'resultado_correcao_screen.dart';
import 'widgets/camera_placeholder.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';

/// Tela de leitura OMR das folhas de respostas e correção automática (Step 2/2 — N3-04 e N3-05).
///
/// Modo Híbrido:
/// 1. Captura ao vivo pela câmera nativa do dispositivo (`CameraController`).
/// 2. Carregamento de imagem de folha (PNG/JPG) via `FilePicker`.
/// 3. Processamento real por Visão Computacional (`OmrImageService`: detecção dos 4 cantos,
///    retificação de perspectiva, leitura de densidade das bolhas e detecção de rasuras/duplas marcações)
///    seguido de revisão interativa e correção automática (`ExamGradingService`).
class LeituraGabaritoScreen extends StatefulWidget {
  const LeituraGabaritoScreen({
    super.key,
    required this.prova,
    this.questions,
    this.students,
    this.variants,
    this.activeVariant,
    this.preScannedSheet,
    this.provasLidas = 0,
    this.errosLeitura = 0,
    this.resultadosIniciais = const [],
    this.onPickSheetImage,
    this.autoConfirmReview = false,
    this.allowSimulatedCapture = false,
  });

  final ProvaCorrecao prova;
  final List<Questao>? questions;
  final List<StudentRecord>? students;
  final List<ExamVariant>? variants;
  final ExamVariant? activeVariant;
  final OmrSheetScanResult? preScannedSheet;
  final int provasLidas;
  final int errosLeitura;
  final List<ResultadoAluno> resultadosIniciais;
  final Future<Uint8List?> Function()? onPickSheetImage;
  final bool autoConfirmReview;

  /// Permite gerar uma folha simulada (marcações inventadas) no lugar da
  /// câmera. **Somente para testes automatizados**: no app nunca é ativado,
  /// pois produziria notas falsas para alunos reais.
  final bool allowSimulatedCapture;

  @override
  State<LeituraGabaritoScreen> createState() => _LeituraGabaritoScreenState();
}

class _LeituraGabaritoScreenState extends State<LeituraGabaritoScreen> {
  final OmrImageService _omrService = const OmrImageService();
  final ExamGradingService _gradingService = const ExamGradingService();
  final ExamRandomizerService _randomizer = const ExamRandomizerService();

  LeituraStatus _status = LeituraStatus.aguardando;
  String? _feedbackText;
  bool _feedbackIsError = false;

  late int _provasLidas;
  late int _errosLeitura;
  late final List<ResultadoAluno> _resultadosCapturados;
  late List<ExamVariant> _availableVariants;
  late ExamVariant _currentVariant;
  final Set<int> _annulledOriginalQuestions = <int>{};

  Set<int> get _currentVariantAnnulledQuestions {
    final set = <int>{};
    for (final q in _currentVariant.questions) {
      if (_annulledOriginalQuestions.contains(q.originalQuestionNumber)) {
        set.add(q.questionNumber);
      }
    }
    return set;
  }

  CameraController? _cameraController;
  bool _useLiveCamera = false;
  bool _initializingCamera = false;

  @override
  void initState() {
    super.initState();

    final totalEsperado = _totalEsperado;
    _provasLidas = totalEsperado > 0 && widget.provasLidas > totalEsperado
        ? totalEsperado
        : widget.provasLidas;
    _errosLeitura = widget.errosLeitura;
    _resultadosCapturados = List<ResultadoAluno>.from(widget.resultadosIniciais);

    _initVariants();

    if (widget.preScannedSheet != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _processarResultadoScan(widget.preScannedSheet!);
        }
      });
    }
  }

  void _initVariants() {
    if (widget.variants != null && widget.variants!.isNotEmpty) {
      _availableVariants = widget.variants!;
    } else if (widget.questions != null && widget.questions!.isNotEmpty) {
      // Só gera a partir das questões reais da prova. Nunca inventa gabarito.
      _availableVariants = _randomizer.generateVariantsForMode(
        examId: widget.prova.id,
        questions: widget.questions!,
        mode: widget.prova.modoAplicacao,
        students: widget.students ?? const [],
        classId: widget.prova.classId,
        className: widget.prova.turma,
      );
    } else {
      _availableVariants = const [];
    }

    if (widget.activeVariant != null) {
      _currentVariant = widget.activeVariant!;
    } else if (_availableVariants.isNotEmpty) {
      _currentVariant = _availableVariants.first;
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  int get _totalEsperado {
    if (widget.students != null && widget.students!.isNotEmpty) {
      return widget.students!.length;
    }
    return widget.prova.totalAlunos;
  }

  bool get _limiteAtingido =>
      _totalEsperado > 0 && _provasLidas >= _totalEsperado;

  int get _folhaAtualExibida {
    final proximaFolha = _provasLidas + 1;
    if (_totalEsperado <= 0) return proximaFolha;
    return proximaFolha > _totalEsperado ? _totalEsperado : proximaFolha;
  }

  String get _textoProgresso {
    if (_totalEsperado <= 0) {
      return 'Folha $_folhaAtualExibida';
    }
    return 'Folha $_folhaAtualExibida de $_totalEsperado';
  }

  StudentRecord get _estudanteAtual {
    // Se a variante (ou folha nominal OMR) já está vinculada a um aluno específico
    if (_currentVariant.studentId != null &&
        _currentVariant.studentId!.isNotEmpty) {
      if (widget.students != null && widget.students!.isNotEmpty) {
        final matched = widget.students!
            .where((s) => s.id == _currentVariant.studentId)
            .toList();
        if (matched.isNotEmpty) return matched.first;
      }
      return StudentRecord(
        id: _currentVariant.studentId!,
        name: _currentVariant.studentName ?? _currentVariant.studentId!,
        matricula: _currentVariant.studentMatricula ?? '',
      );
    }

    if (widget.students != null && widget.students!.isNotEmpty) {
      // Sugere o primeiro aluno que ainda não foi corrigido nesta sessão.
      final corrigidos =
          _resultadosCapturados.map((r) => r.studentId).whereType<String>().toSet();
      for (final s in widget.students!) {
        if (!corrigidos.contains(s.id)) return s;
      }
      return widget.students!.last;
    }

    return StudentRecord(
      id: 'aluno_${_provasLidas + 1}',
      name: _currentVariant.studentName ?? 'Aluno ${_provasLidas + 1}',
    );
  }

  Future<void> _toggleLiveCamera() async {
    if (_useLiveCamera) {
      await _cameraController?.dispose();
      setState(() {
        _cameraController = null;
        _useLiveCamera = false;
      });
      return;
    }

    setState(() => _initializingCamera = true);
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (!mounted) return;
        setState(() {
          _initializingCamera = false;
          _feedbackText =
              'Nenhuma câmera física encontrada neste dispositivo. Use "Carregar imagem da folha".';
          _feedbackIsError = true;
        });
        return;
      }

      final controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _useLiveCamera = true;
        _initializingCamera = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _initializingCamera = false;
        _feedbackText =
            'Câmera indisponível neste ambiente ($error). Use "Carregar imagem da folha".';
        _feedbackIsError = true;
      });
    }
  }

  /// Captura foto da câmera nativa (se ativa) ou gera e processa folha OMR real
  /// através do motor de visão computacional `OmrImageService`.
  Future<void> _capturarFolhaCameraOuSintetica() async {
    if (_limiteAtingido) return;

    final cameraPronta = _useLiveCamera &&
        _cameraController != null &&
        _cameraController!.value.isInitialized;
    if (!cameraPronta && !widget.allowSimulatedCapture) {
      // Sem câmera, nunca gera folha simulada: liga a câmera.
      await _toggleLiveCamera();
      return;
    }

    setState(() {
      _status = LeituraStatus.processando;
      _feedbackText = null;
      _feedbackIsError = false;
    });

    try {
      Uint8List imageBytes;

      if (_useLiveCamera &&
          _cameraController != null &&
          _cameraController!.value.isInitialized) {
        final xFile = await _cameraController!.takePicture();
        imageBytes = await xFile.readAsBytes();
      } else {
        // Gera uma imagem PNG real de folha OMR com marcadores fiduciais, QR Code
        // e inclinação de perspectiva para passar pelo pipeline real de visão computacional!
        final student = _estudanteAtual;
        final simulatedMarks = <int, List<String>>{};
        for (final q in _currentVariant.questions) {
          final qNum = q.questionNumber;
          final correctLetter =
              _currentVariant.answerKey[qNum] ?? q.correctLetter;
          final hash = (student.name.hashCode ^ (qNum * 31)).abs() % 10;
          if (hash == 0) {
            // 10% em branco para demonstrar detecção de questão não respondida
            simulatedMarks[qNum] = const [];
          } else if (hash == 1) {
            // 10% alternativa incorreta
            final wrong = OmrLayoutSpec.letters
                .firstWhere((l) => l != correctLetter, orElse: () => 'B');
            simulatedMarks[qNum] = [wrong];
          } else {
            simulatedMarks[qNum] = [correctLetter];
          }
        }

        imageBytes = _omrService.renderSyntheticSheetPng(
          qrPayload: _currentVariant.qrPayload,
          totalQuestions: _currentVariant.questions.length,
          markedAnswers: simulatedMarks,
          simulatePerspectiveSkew: true,
        );
      }

      final scanResult = _omrService.processSheetBytes(
        imageBytes: imageBytes,
        expectedQuestions: _currentVariant.questions.length,
      );

      if (!mounted) return;
      await _processarResultadoScan(scanResult);
    } catch (error) {
      if (!mounted) return;
      _errosLeitura++;
      setState(() {
        _status = LeituraStatus.erro;
        _feedbackText = 'Falha ao processar folha OMR: $error';
        _feedbackIsError = true;
      });
    }
  }

  /// Seleciona uma imagem PNG/JPG de folha de respostas do dispositivo e executa
  /// o pipeline completo de visão computacional (`OmrImageService`).
  Future<void> _carregarImagemFolha() async {
    if (_limiteAtingido) return;

    setState(() {
      _status = LeituraStatus.processando;
      _feedbackText = null;
      _feedbackIsError = false;
    });

    try {
      Uint8List? bytes;
      if (widget.onPickSheetImage != null) {
        bytes = await widget.onPickSheetImage!();
      } else {
        final files = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: const ['png', 'jpg', 'jpeg'],
        );
        if (files.isNotEmpty) {
          bytes = await files.first.readAsBytes();
        }
      }

      if (!mounted) return;
      if (bytes == null) {
        setState(() => _status = LeituraStatus.aguardando);
        return;
      }

      final scanResult = _omrService.processSheetBytes(
        imageBytes: bytes,
        expectedQuestions: _currentVariant.questions.length,
      );

      await _processarResultadoScan(scanResult);
    } catch (error) {
      if (!mounted) return;
      _errosLeitura++;
      setState(() {
        _status = LeituraStatus.erro;
        _feedbackText = 'Não foi possível ler a imagem da folha: $error';
        _feedbackIsError = true;
      });
    }
  }

  void _recusarFolha(String message) {
    _errosLeitura++;
    setState(() {
      _status = LeituraStatus.erro;
      _feedbackText = message;
      _feedbackIsError = true;
    });
  }

  Future<void> _processarResultadoScan(OmrSheetScanResult scanResult) async {
    // Sem os 4 marcadores, a posição das bolhas não é confiável: recusa.
    final sheetError = SheetQrValidator.sheetError(scanResult);
    if (sheetError != null) {
      _recusarFolha(sheetError);
      return;
    }

    // Se o QR Code foi lido, ele precisa ser desta prova/turma. Nunca usa
    // outra variante como "plano B".
    if (scanResult.qrPayload != null) {
      final match = SheetQrValidator.match(
        payload: scanResult.qrPayload!,
        examId: widget.prova.id,
        variants: _availableVariants,
        students: widget.students ?? const [],
      );
      if (!match.isOk) {
        _recusarFolha(match.error!);
        return;
      }
      _currentVariant = match.variant!;
    } else if (scanResult.rawQrText != null) {
      _recusarFolha('QR Code inválido. Use uma folha gerada pelo Avalia Pro.');
      return;
    }

    final initialMarks = <int, List<String>>{
      for (final entry in scanResult.questions.entries)
        entry.key: List<String>.from(entry.value.markedLetters),
    };

    if (widget.autoConfirmReview) {
      await _registrarCorrecaoConfirmada(
        student: _estudanteAtual,
        markedLettersByQuestion: initialMarks,
      );
      return;
    }

    if (mounted) {
      setState(() => _status = LeituraStatus.aguardando);
    }

    final confirmed = await _abrirModalRevisaoOmr(
      scanResult: scanResult,
      initialMarks: initialMarks,
    );

    if (!mounted) return;
    if (confirmed == null) {
      setState(() {
        _status = LeituraStatus.aguardando;
        _feedbackText = 'Leitura descartada pelo professor.';
        _feedbackIsError = false;
      });
      return;
    }

    await _registrarCorrecaoConfirmada(
      student: confirmed.student,
      markedLettersByQuestion: confirmed.marks,
    );
  }

  /// Prova individual: cada folha começa pelo QR Code (passo 1).
  void _voltarParaLeituraQr() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LeituraQrScreen(
          prova: widget.prova,
          questions: widget.questions,
          students: widget.students,
          variants: _availableVariants,
          provasLidas: _provasLidas,
          errosLeitura: _errosLeitura,
          resultadosAcumulados: _resultadosCapturados,
        ),
      ),
    );
  }

  Future<void> _registrarCorrecaoConfirmada({
    required StudentRecord student,
    required Map<int, List<String>> markedLettersByQuestion,
  }) async {
    final gradeResult = _gradingService.gradeFromMarkedLetters(
      variant: _currentVariant,
      markedLettersByQuestion: markedLettersByQuestion,
      annulledQuestions: _currentVariantAnnulledQuestions,
    );

    final novoResultado = ResultadoAluno(
      studentId: student.id,
      nomeAluno: student.name,
      acertos: gradeResult.correctCount,
      totalQuestoes: gradeResult.totalQuestions,
      variantId: gradeResult.variantId,
      variantCode: gradeResult.variantCode,
      emBranco: gradeResult.blankCount,
      invalidas: gradeResult.invalidMultipleCount,
      notaFinal10: gradeResult.finalGrade,
      answers: gradeResult.answers,
    );

    // O mesmo aluno não pode entrar duas vezes na mesma correção.
    final indiceExistente =
        _resultadosCapturados.indexWhere((r) => r.studentId == student.id);
    if (indiceExistente >= 0) {
      final anterior = _resultadosCapturados[indiceExistente];
      final substituir = await AppDialog.confirm(
        context: context,
        title: 'Aluno já corrigido nesta sessão',
        message:
            'A folha de ${student.name} já foi lida (nota ${anterior.nota10.toStringAsFixed(1)}). '
            'Substituir pela nova leitura (nota ${gradeResult.finalGrade.toStringAsFixed(1)})?',
        confirmLabel: 'Substituir',
        cancelLabel: 'Manter a anterior',
      );
      if (!mounted) return;
      if (substituir != true) {
        if (widget.prova.provaIndividual) {
          // Volta ao passo 1: a próxima folha é identificada pelo próprio QR,
          // e não pela prova do aluno anterior.
          _voltarParaLeituraQr();
          return;
        }
        setState(() {
          _status = LeituraStatus.aguardando;
          _feedbackText =
              'Nova leitura descartada: ${student.name} já tinha sido corrigido(a).';
          _feedbackIsError = false;
        });
        return;
      }
      _resultadosCapturados[indiceExistente] = novoResultado;
    } else {
      _provasLidas++;
      _resultadosCapturados.add(novoResultado);
    }

    // Restaura a variante compartilhada base caso a folha anterior tenha sido nominal
    if (!widget.prova.provaIndividual) {
      final base = _availableVariants
          .where((v) => v.id == _currentVariant.id)
          .toList();
      if (base.isNotEmpty) {
        _currentVariant = base.first;
      }
    }

    final concluiuTodasAsFolhas = _limiteAtingido;

    setState(() {
      _status = LeituraStatus.sucesso;
      _feedbackText = concluiuTodasAsFolhas
          ? 'Folha de ${student.name} corrigida (${gradeResult.correctCount}/${gradeResult.totalQuestions}). '
              'Todas as $_totalEsperado folhas previstas foram processadas.'
          : 'Folha de ${student.name} corrigida: '
              '${gradeResult.correctCount}/${gradeResult.totalQuestions} acertos '
              '(Nota ${gradeResult.finalGrade.toStringAsFixed(1)})';
      _feedbackIsError = false;
    });

    if (concluiuTodasAsFolhas) return;

    if (widget.prova.provaIndividual) {
      _voltarParaLeituraQr();
      return;
    }

    setState(() {
      _status = LeituraStatus.aguardando;
    });
  }

  Future<({StudentRecord student, Map<int, List<String>> marks})?>
      _abrirModalRevisaoOmr({
    required OmrSheetScanResult scanResult,
    required Map<int, List<String>> initialMarks,
  }) {
    var selectedStudent = _estudanteAtual;
    final availableStudents =
        (widget.students != null && widget.students!.isNotEmpty)
            ? widget.students!
            : [selectedStudent];
    if (!availableStudents.any((s) => s.id == selectedStudent.id)) {
      selectedStudent = availableStudents.first;
    }

    final editableMarks = <int, List<String>>{
      for (final entry in initialMarks.entries)
        entry.key: List<String>.from(entry.value),
    };

    return showModalBottomSheet<
        ({StudentRecord student, Map<int, List<String>> marks})>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final previewGrade = _gradingService.gradeFromMarkedLetters(
              variant: _currentVariant,
              markedLettersByQuestion: editableMarks,
              annulledQuestions: _currentVariantAnnulledQuestions,
            );
            final theme = Theme.of(ctx);
            final colorScheme = theme.colorScheme;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: SizedBox(
                  height: MediaQuery.of(ctx).size.height * 0.78,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Revisão OMR e Correção (${_currentVariant.label})',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        scanResult.perspectiveCorrected
                            ? 'Perspectiva retificada (4 marcadores fiduciais) • '
                                'Nota prévia: ${previewGrade.finalGrade.toStringAsFixed(1)}/10 '
                                '(${previewGrade.correctCount}/${previewGrade.totalQuestions})'
                            : 'Nota prévia: ${previewGrade.finalGrade.toStringAsFixed(1)}/10 '
                                '(${previewGrade.correctCount}/${previewGrade.totalQuestions})',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (previewGrade.blankCount > 0 ||
                          previewGrade.invalidMultipleCount > 0) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Atenção: ${previewGrade.blankCount} em branco • '
                          '${previewGrade.invalidMultipleCount} marcação(ões) dupla(s)/inválida(s)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedStudent.id,
                        decoration: const InputDecoration(
                          labelText: 'Aluno(a)',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        items: availableStudents.map((s) {
                          return DropdownMenuItem(
                            value: s.id,
                            child: Text(s.name),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() {
                              selectedStudent = availableStudents
                                  .firstWhere((s) => s.id == val);
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.separated(
                          itemCount: _currentVariant.questions.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (_, index) {
                            final q = _currentVariant.questions[index];
                            final qNum = q.questionNumber;
                            final expected =
                                _currentVariant.answerKey[qNum] ?? q.correctLetter;
                            final marked = editableMarks[qNum] ?? <String>[];
                            final isAnnulled = _annulledOriginalQuestions
                                .contains(q.originalQuestionNumber);

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 68,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Q${qNum.toString().padLeft(2, '0')}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          isAnnulled
                                              ? 'Anulada'
                                              : 'Gab: $expected',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                            color: isAnnulled
                                                ? colorScheme.primary
                                                : colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        ...(q.alternatives.isNotEmpty
                                                ? q.alternatives
                                                    .map((a) => a.letter)
                                                    .toList()
                                                : OmrLayoutSpec.letters)
                                            .map((letter) {
                                          final isSelected =
                                              marked.contains(letter);
                                          return FilterChip(
                                            label: Text(letter),
                                            selected: isSelected,
                                            visualDensity: VisualDensity.compact,
                                            onSelected: (sel) {
                                              setModalState(() {
                                                final list = List<String>.from(
                                                  editableMarks[qNum] ?? [],
                                                );
                                                if (sel) {
                                                  list
                                                    ..clear()
                                                    ..add(letter);
                                                } else {
                                                  list.remove(letter);
                                                }
                                                editableMarks[qNum] = list;
                                              });
                                            },
                                          );
                                        }),
                                        FilterChip(
                                          label: const Text('Anular'),
                                          selected: isAnnulled,
                                          visualDensity: VisualDensity.compact,
                                          onSelected: (sel) {
                                            setModalState(() {
                                              if (sel) {
                                                _annulledOriginalQuestions
                                                    .add(q.originalQuestionNumber);
                                              } else {
                                                _annulledOriginalQuestions
                                                    .remove(q.originalQuestionNumber);
                                              }
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Descartar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => Navigator.of(ctx).pop((
                                student: selectedStudent,
                                marks: editableMarks,
                              )),
                              icon: const Icon(AppIcons.confirm),
                              label: const Text('Confirmar Nota'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _finalizar() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultadoCorrecaoScreen(
          prova: widget.prova,
          resultados: _resultadosCapturados,
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

    if (_availableVariants.isEmpty && widget.activeVariant == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Correção OMR • 2/2')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Não foi possível carregar o gabarito desta prova. '
              'Volte e tente iniciar a correção novamente.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmarCancelamento();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Correção OMR • 2/2'),
          leading: IconButton(
            icon: const Icon(AppIcons.close),
            onPressed: _confirmarCancelamento,
          ),
          actions: [
            IconButton(
              icon: Icon(
                _useLiveCamera ? AppIcons.cameraOff : AppIcons.cameraOn,
              ),
              tooltip: _useLiveCamera
                  ? 'Desativar câmera nativa'
                  : 'Ativar câmera nativa',
              onPressed: _initializingCamera ? null : _toggleLiveCamera,
            ),
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
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              Text(
                'Leitura OMR das Folhas',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Variante ativa: ${_currentVariant.label} (${_currentVariant.code})',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              if (_useLiveCamera &&
                  _cameraController != null &&
                  _cameraController!.value.isInitialized)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 220,
                    width: double.infinity,
                    child: CameraPreview(_cameraController!),
                  ),
                )
              else
                CameraPlaceholder(
                  label: 'OMR • ${_currentVariant.code}',
                  status: _status,
                  icon: _status == LeituraStatus.aguardando
                      ? Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              _currentVariant.code[0].toUpperCase(),
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
              const SizedBox(height: 14),
              AppCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _textoProgresso,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _limiteAtingido
                          ? 'Todas as folhas previstas foram processadas'
                          : 'Próximo aluno sugerido: ${_estudanteAtual.name}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (_feedbackText != null) ...[
                const SizedBox(height: 12),
                Text(
                  _feedbackText!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: _feedbackIsError
                        ? colorScheme.error
                        : AppColors.success,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              AppButton(
                label: _limiteAtingido
                    ? 'Todas as folhas processadas'
                    : _status == LeituraStatus.processando
                        ? 'Processando OMR...'
                        : _useLiveCamera
                            ? 'Capturar foto da câmera (OMR)'
                            : widget.allowSimulatedCapture
                                ? 'Simular Leitura OMR (${_currentVariant.code})'
                                : (_initializingCamera
                                    ? 'Abrindo câmera...'
                                    : 'Ativar câmera'),
                icon: _limiteAtingido || _status == LeituraStatus.processando
                    ? null
                    : (_useLiveCamera || widget.allowSimulatedCapture
                        ? AppIcons.correction
                        : AppIcons.cameraOn),
                isLoading: _status == LeituraStatus.processando,
                expanded: true,
                onPressed: _status != LeituraStatus.processando &&
                        !_limiteAtingido &&
                        !_initializingCamera
                    ? _capturarFolhaCameraOuSintetica
                    : null,
              ),
              const SizedBox(height: 10),
              if (!_limiteAtingido)
                AppButton(
                  label: 'Carregar imagem de folha (PNG/JPG)',
                  icon: AppIcons.pickImage,
                  variant: AppButtonVariant.secondary,
                  expanded: true,
                  onPressed: _status != LeituraStatus.processando
                      ? _carregarImagemFolha
                      : null,
                ),
              if (_provasLidas > 0) ...[
                const SizedBox(height: 10),
                AppButton(
                  label: 'Ver resultados e concluir ($_provasLidas lida(s))',
                  icon: AppIcons.confirm,
                  variant: AppButtonVariant.text,
                  expanded: true,
                  onPressed:
                      _status != LeituraStatus.processando ? _finalizar : null,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
