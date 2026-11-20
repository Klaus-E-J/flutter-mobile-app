import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../features/classes/data/class_repository.dart';
import '../../../features/correction/services/omr_image_service.dart';
import '../../../features/correction/services/sheet_qr_validator.dart';
import '../../../features/exams/models/exam_variant.dart';
import '../../../features/exams/services/exam_randomizer_service.dart';
import '../provas/models/questao_model.dart';
import 'leitura_gabarito_screen.dart';
import 'models/correcao_models.dart';
import 'resultado_correcao_screen.dart';
import 'widgets/camera_placeholder.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';

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
      return;
    }

    // Sugere a próxima prova ainda não corrigida nesta sessão.
    final corrected = widget.resultadosAcumulados
        .map((r) => r.studentId)
        .whereType<String>()
        .toSet();
    _selectedVariant = _availableVariants.firstWhere(
      (v) => v.studentId == null || !corrected.contains(v.studentId),
      orElse: () => _availableVariants.first,
    );
  }

  void _mostrarErro(String message) {
    setState(() {
      _status = LeituraStatus.erro;
      _feedbackText = message;
      _feedbackIsError = true;
    });
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
      _mostrarErro('QR Code inválido. Use uma folha gerada pelo Avalia Pro.');
      return;
    }

    final match = SheetQrValidator.match(
      payload: parsed,
      examId: widget.prova.id,
      variants: _availableVariants,
      students: widget.students ?? const [],
    );
    if (!match.isOk) {
      _mostrarErro(match.error!);
      return;
    }
    final chosenVariant = match.variant!;

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

      if (scanResult.rawQrText == null) {
        // Sem QR legível não há como saber de quem é a folha: nunca
        // presume a variante selecionada.
        _mostrarErro(
          SheetQrValidator.sheetError(scanResult) ?? SheetQrValidator.msgQrNotFound,
        );
        return;
      }
      // QR lido. As respostas só são aproveitadas se a folha inteira foi
      // detectada; senão o professor fotografa a folha no passo 2.
      _processarQrCodeBruto(
        scanResult.rawQrText!,
        preScannedSheet:
            SheetQrValidator.sheetError(scanResult) == null ? scanResult : null,
      );
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

  bool get _temLeituras => widget.resultadosAcumulados.isNotEmpty;

  /// Encerra a sessão com as folhas já lidas (ex.: alunos ausentes).
  void _finalizar() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultadoCorrecaoScreen(
          prova: widget.prova,
          resultados: widget.resultadosAcumulados,
          totalErros: widget.errosLeitura,
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

    if (_availableVariants.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Correção • 1/2')),
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
          title: const Text('Correção • 1/2'),
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
                  ? 'Desativar câmera ao vivo'
                  : 'Ativar câmera ao vivo',
              onPressed: _toggleLiveCamera,
            ),
            if (_temLeituras)
              TextButton(
                onPressed: _status == LeituraStatus.processando ? null : _finalizar,
                child: const Text('Finalizar'),
              ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              Text(
                'Identificar QR Code da Folha',
                style: theme.textTheme.headlineSmall,
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
                      ? const Icon(AppIcons.qrCode, color: Colors.white, size: 28)
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
                        : AppColors.success,
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
                    : AppIcons.scanQr,
                isLoading: _status == LeituraStatus.processando,
                expanded: true,
                onPressed: _status == LeituraStatus.processando
                    ? null
                    : _confirmarVarianteSelecionada,
              ),
              const SizedBox(height: 10),
              AppButton(
                label: 'Carregar imagem de folha (PNG/JPG)',
                icon: AppIcons.pickImage,
                variant: AppButtonVariant.secondary,
                expanded: true,
                onPressed: _status == LeituraStatus.processando
                    ? null
                    : _carregarImagemFolha,
              ),
              if (_temLeituras) ...[
                const SizedBox(height: 10),
                AppButton(
                  label:
                      'Ver resultados e concluir (${widget.resultadosAcumulados.length} lida(s))',
                  icon: AppIcons.confirm,
                  variant: AppButtonVariant.text,
                  expanded: true,
                  onPressed:
                      _status == LeituraStatus.processando ? null : _finalizar,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
