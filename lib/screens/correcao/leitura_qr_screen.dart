import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../features/classes/data/class_repository.dart';
import '../../../features/correction/services/omr_image_service.dart';
import '../../../features/exams/models/exam_variant.dart';
import '../../../features/exams/services/exam_randomizer_service.dart';
import '../provas/models/questao_model.dart';
import 'leitura_gabarito_screen.dart';
import 'models/correcao_models.dart';
import 'widgets/camera_placeholder.dart';

/// Tela de leitura do QR Code da prova (Step 1/2 — N3-04).
///
/// Modo Híbrido:
/// 1. Câmera nativa ao vivo via `MobileScanner` para ler o QR Code (`AVALIA:1.0|...`).
/// 2. Carregamento de imagem de folha (PNG/JPG) via `FilePicker` + decodificador `zxing2` / OMR.
/// 3. Seleção direta de variante gerada (Caderno A, B, C, D ou Individual) para emulador/desktop.
class LeituraQrScreen extends StatefulWidget {
  const LeituraQrScreen({
    super.key,
    required this.prova,
    this.questions,
    this.students,
    this.variants,
    this.provasLidas = 0,
    this.errosLeitura = 0,
    this.resultadosAcumulados = const [],
    this.onPickSheetImage,
  });

  final ProvaCorrecao prova;
  final List<Questao>? questions;
  final List<StudentRecord>? students;
  final List<ExamVariant>? variants;
  final int provasLidas;
  final int errosLeitura;
  final List<ResultadoAluno> resultadosAcumulados;
  final Future<Uint8List?> Function()? onPickSheetImage;

  @override
  State<LeituraQrScreen> createState() => _LeituraQrScreenState();
}

class _LeituraQrScreenState extends State<LeituraQrScreen> {
  final OmrImageService _omrService = const OmrImageService();
  final ExamRandomizerService _randomizer = const ExamRandomizerService();

  LeituraStatus _status = LeituraStatus.aguardando;
  String? _feedbackText;
  bool _feedbackIsError = false;
  bool _useLiveCamera = false;
  MobileScannerController? _scannerController;

  late List<ExamVariant> _availableVariants;
  late ExamVariant _selectedVariant;

  @override
  void initState() {
    super.initState();
    _initVariants();
  }

  void _initVariants() {
    final provided = widget.variants;
    if (provided != null && provided.isNotEmpty) {
      _availableVariants = provided;
    } else {
      final qs = widget.questions != null && widget.questions!.isNotEmpty
          ? widget.questions!
          : List<Questao>.generate(
              widget.prova.totalQuestoes > 0 ? widget.prova.totalQuestoes : 5,
              (i) => Questao(
                id: 'q_${i + 1}',
                enunciado: 'Questão ${i + 1}',
                alternativas: [
                  Alternativa(id: 'a', texto: 'A', correta: i % 4 == 0),
                  Alternativa(id: 'b', texto: 'B', correta: i % 4 == 1),
                  Alternativa(id: 'c', texto: 'C', correta: i % 4 == 2),
                  Alternativa(id: 'd', texto: 'D', correta: i % 4 == 3),
                  Alternativa(id: 'e', texto: 'E'),
                ],
              ),
            );
      _availableVariants = _randomizer.generateVariants(
        examId: widget.prova.id,
        questions: qs,
        sameExamForEveryone: !widget.prova.provaIndividual,
        students: widget.students ?? const [],
        classId: widget.prova.classId,
        className: widget.prova.turma,
      );
    }

    final defaultIdx = widget.provasLidas < _availableVariants.length
        ? widget.provasLidas
        : 0;
    _selectedVariant = _availableVariants[defaultIdx];
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  void _toggleLiveCamera() {
    setState(() {
      _useLiveCamera = !_useLiveCamera;
      if (_useLiveCamera) {
        _scannerController ??= MobileScannerController(
          detectionSpeed: DetectionSpeed.noDuplicates,
        );
      } else {
        _scannerController?.stop();
      }
    });
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_status == LeituraStatus.processando || _status == LeituraStatus.sucesso) {
      return;
    }
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw != null && raw.isNotEmpty) {
        _processarQrCodeBruto(raw);
        return;
      }
    }
  }

  void _processarQrCodeBruto(
    String rawQr, {
    OmrSheetScanResult? preScannedSheet,
  }) {
    final parsed = ExamQrPayload.tryParse(rawQr);
    if (parsed == null) {
      setState(() {
        _status = LeituraStatus.erro;
        _feedbackText =
            'QR Code inválido ("$rawQr"). Use uma folha gerada pelo Avalia Pro.';
        _feedbackIsError = true;
      });
      return;
    }

    final matched = _availableVariants
        .where((v) => v.id == parsed.variantId)
        .toList();
    final chosenVariant =
        matched.isNotEmpty ? matched.first : _selectedVariant;

    setState(() {
      _selectedVariant = chosenVariant;
      _status = LeituraStatus.sucesso;
      _feedbackText =
          'QR Code reconhecido: ${chosenVariant.label} (${chosenVariant.questions.length} questões)';
      _feedbackIsError = false;
    });

    _avancarParaGabarito(
      variant: chosenVariant,
      preScannedSheet: preScannedSheet,
    );
  }

  Future<void> _carregarImagemFolha() async {
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
        expectedQuestions: _selectedVariant.questions.length,
      );

      if (scanResult.rawQrText != null) {
        _processarQrCodeBruto(
          scanResult.rawQrText!,
          preScannedSheet: scanResult,
        );
      } else {
        // Imagem sem QR legível, mas com bolhas detectadas -> avança com a variante selecionada
        setState(() {
          _status = LeituraStatus.sucesso;
          _feedbackText =
              'Folha carregada (${_selectedVariant.label}). Avançando para revisão OMR.';
          _feedbackIsError = false;
        });
        _avancarParaGabarito(
          variant: _selectedVariant,
          preScannedSheet: scanResult,
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _status = LeituraStatus.erro;
        _feedbackText = 'Não foi possível ler a imagem: $error';
        _feedbackIsError = true;
      });
    }
  }

  void _confirmarVarianteSelecionada() {
    _processarQrCodeBruto(_selectedVariant.qrPayload);
  }

  void _avancarParaGabarito({
    required ExamVariant variant,
    OmrSheetScanResult? preScannedSheet,
  }) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LeituraGabaritoScreen(
          prova: widget.prova,
          questions: widget.questions,
          students: widget.students,
          variants: _availableVariants,
          activeVariant: variant,
          preScannedSheet: preScannedSheet,
          provasLidas: widget.provasLidas,
          errosLeitura: widget.errosLeitura,
          resultadosIniciais: widget.resultadosAcumulados,
        ),
      ),
    );
  }

  Future<void> _confirmarCancelamento() async {
    final msg = widget.provasLidas > 0
        ? 'Você já capturou ${widget.provasLidas} gabarito(s). '
            'Se sair agora, esse progresso será perdido.'
        : 'Se sair agora, a correção será cancelada.';

    bool? sair;
    await AppDialog.show(
      context: context,
      title: 'Cancelar correção?',
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
          title: const Text('Correção • 1/2'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _confirmarCancelamento,
          ),
          actions: [
            IconButton(
              icon: Icon(
                _useLiveCamera ? Icons.videocam_off_outlined : Icons.videocam_outlined,
              ),
              tooltip: _useLiveCamera
                  ? 'Desativar câmera ao vivo'
                  : 'Ativar câmera ao vivo',
              onPressed: _toggleLiveCamera,
            ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              Text(
                'Identificar QR Code da Folha',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Escaneie pela câmera, carregue a foto da folha ou selecione o caderno.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              if (_useLiveCamera && _scannerController != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 220,
                    width: double.infinity,
                    child: MobileScanner(
                      controller: _scannerController!,
                      onDetect: _onBarcodeDetected,
                    ),
                  ),
                )
              else
                CameraPlaceholder(
                  label: 'QR CODE • ${_selectedVariant.code}',
                  status: _status,
                  icon: _status == LeituraStatus.aguardando
                      ? const Icon(Icons.qr_code, color: Colors.white, size: 28)
                      : null,
                ),
              const SizedBox(height: 14),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Variante / Caderno da Folha',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<ExamVariant>(
                      initialValue: _selectedVariant,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      items: _availableVariants.map((v) {
                        return DropdownMenuItem(
                          value: v,
                          child: Text(
                            '${v.label} (${v.code})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => _selectedVariant = v);
                        }
                      },
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
                        : const Color(0xFF16A34A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              AppButton(
                label: _status == LeituraStatus.processando
                    ? 'Processando...'
                    : 'Confirmar QR Code (${_selectedVariant.code})',
                icon: _status == LeituraStatus.processando
                    ? null
                    : Icons.qr_code_scanner,
                isLoading: _status == LeituraStatus.processando,
                expanded: true,
                onPressed: _status == LeituraStatus.processando
                    ? null
                    : _confirmarVarianteSelecionada,
              ),
              const SizedBox(height: 10),
              AppButton(
                label: 'Carregar imagem de folha (PNG/JPG)',
                icon: Icons.image_search_outlined,
                variant: AppButtonVariant.secondary,
                expanded: true,
                onPressed: _status == LeituraStatus.processando
                    ? null
                    : _carregarImagemFolha,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
