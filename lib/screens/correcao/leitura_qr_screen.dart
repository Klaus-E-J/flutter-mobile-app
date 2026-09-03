import 'package:flutter/material.dart';

import 'models/correcao_models.dart';
import 'widgets/camera_placeholder.dart';
import 'leitura_gabarito_screen.dart';

/// Tela de leitura do QR Code da prova (Step 1/2).
///
/// O QR Code contém a sequência das questões e as respostas
/// corretas. Quando a prova é individual (`provaIndividual`),
/// esta tela é revisitada antes de cada gabarito do aluno
/// para ler o QR específico dele. O professor lê na ordem
/// que quiser — o QR identifica o aluno automaticamente.
class LeituraQrScreen extends StatefulWidget {
  const LeituraQrScreen({
    super.key,
    required this.prova,
    this.provasLidas = 0,
    this.errosLeitura = 0,
  });

  final ProvaCorrecao prova;

  /// Progresso acumulado (usado no loop de prova individual).
  final int provasLidas;
  final int errosLeitura;

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

    // Avança para leitura do gabarito do aluno
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LeituraGabaritoScreen(
          prova: widget.prova,
          provasLidas: widget.provasLidas,
          errosLeitura: widget.errosLeitura,
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

    final sair = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar correção?'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Continuar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sair'),
          ),
        ],
      ),
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
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Título
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

              // Câmera simulada
              CameraPlaceholder(
                label: 'QR CODE',
                status: _status,
                icon: _status == LeituraStatus.aguardando
                    ? const Icon(Icons.qr_code, color: Colors.white, size: 28)
                    : null,
              ),

              const SizedBox(height: 16),

              // Feedback
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

              // Botão principal
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _status == LeituraStatus.aguardando
                      ? _capturar
                      : null,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Capturar QR Code'),
                ),
              ),

              const SizedBox(height: 8),

              // Simular erro (para testes)
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
    );
  }
}
