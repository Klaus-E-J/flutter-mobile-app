import 'package:flutter/material.dart';

import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../features/classes/data/class_repository.dart';
import '../provas/models/questao_model.dart';
import 'leitura_gabarito_screen.dart';
import 'models/correcao_models.dart';
import 'widgets/camera_placeholder.dart';

/// Tela de leitura do QR Code da prova (Step 1/2).
class LeituraQrScreen extends StatefulWidget {
  const LeituraQrScreen({
    super.key,
    required this.prova,
    this.questions,
    this.students,
    this.provasLidas = 0,
    this.errosLeitura = 0,
    this.resultadosAcumulados = const [],
  });

  final ProvaCorrecao prova;
  final List<Questao>? questions;
  final List<StudentRecord>? students;
  final int provasLidas;
  final int errosLeitura;
  final List<ResultadoAluno> resultadosAcumulados;

  @override
  State<LeituraQrScreen> createState() => _LeituraQrScreenState();
}

class _LeituraQrScreenState extends State<LeituraQrScreen> {
  LeituraStatus _status = LeituraStatus.aguardando;
  String? _feedbackText;
  bool _feedbackIsError = false;

  /// Simula leitura do QR Code com sucesso.
  Future<void> _capturar() async {
    setState(() {
      _status = LeituraStatus.processando;
      _feedbackText = null;
    });

    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    setState(() {
      _status = LeituraStatus.sucesso;
      _feedbackText =
          '${widget.prova.totalQuestoes} questões identificadas';
      _feedbackIsError = false;
    });

    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LeituraGabaritoScreen(
          prova: widget.prova,
          questions: widget.questions,
          students: widget.students,
          provasLidas: widget.provasLidas,
          errosLeitura: widget.errosLeitura,
          resultadosIniciais: widget.resultadosAcumulados,
        ),
      ),
    );
  }

  /// Simula erro na leitura.
  Future<void> _simularErro() async {
    setState(() {
      _status = LeituraStatus.processando;
      _feedbackText = null;
    });

    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    setState(() {
      _status = LeituraStatus.erro;
      _feedbackText = 'QR Code não reconhecido. Tente novamente.';
      _feedbackIsError = true;
    });

    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    setState(() {
      _status = LeituraStatus.aguardando;
    });
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
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  'Ler QR Code',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Identifica a sequência e as respostas da prova',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                CameraPlaceholder(
                  label: 'QR CODE',
                  status: _status,
                  icon: _status == LeituraStatus.aguardando
                      ? const Icon(Icons.qr_code, color: Colors.white, size: 28)
                      : null,
                ),
                const SizedBox(height: 16),
                if (_feedbackText != null)
                  Text(
                    _feedbackText!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _feedbackIsError
                          ? colorScheme.error
                          : const Color(0xFF16A34A),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const Spacer(),
                AppButton(
                  label: _status == LeituraStatus.processando
                      ? 'Processando...'
                      : 'Capturar QR Code',
                  icon: _status == LeituraStatus.processando
                      ? null
                      : Icons.qr_code_scanner,
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
