import 'package:flutter/material.dart';

import 'models/correcao_models.dart';
import 'widgets/camera_placeholder.dart';
import 'captura_provas_screen.dart';

/// Tela de leitura de QR Code e Gabarito (Step 2).
///
/// Fluxo sequencial em duas fases:
///   1. Ler o QR Code da prova (identifica variante/prova).
///   2. Ler o gabarito (folha de respostas do professor).
///
/// Ao concluir ambas as leituras, navega para a captura de provas.
class LeituraQrGabaritoScreen extends StatefulWidget {
  const LeituraQrGabaritoScreen({super.key, required this.prova});

  final ProvaCorrecao prova;

  @override
  State<LeituraQrGabaritoScreen> createState() =>
      _LeituraQrGabaritoScreenState();
}

enum _Fase { qrCode, gabarito }

class _LeituraQrGabaritoScreenState extends State<LeituraQrGabaritoScreen> {
  _Fase _fase = _Fase.qrCode;
  LeituraStatus _status = LeituraStatus.aguardando;
  String? _mensagemErro;
  String? _mensagemSucesso;

  /// Simula a leitura com sucesso.
  Future<void> _simularSucesso() async {
    setState(() {
      _status = LeituraStatus.processando;
      _mensagemErro = null;
      _mensagemSucesso = null;
    });

    // Simula tempo de processamento
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    setState(() {
      _status = LeituraStatus.sucesso;
      _mensagemSucesso = _fase == _Fase.qrCode
          ? 'QR Code lido com sucesso! Prova identificada.'
          : 'Gabarito lido com sucesso! ${widget.prova.totalQuestoes} respostas registradas.';
    });

    // Após breve pausa, avança para próxima fase ou tela
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    if (_fase == _Fase.qrCode) {
      // Avança para leitura do gabarito
      setState(() {
        _fase = _Fase.gabarito;
        _status = LeituraStatus.aguardando;
        _mensagemSucesso = null;
      });
    } else {
      // Ambas leituras concluídas → navega para captura
      _navegarParaCaptura();
    }
  }

  /// Simula falha na leitura.
  Future<void> _simularErro() async {
    setState(() {
      _status = LeituraStatus.processando;
      _mensagemErro = null;
      _mensagemSucesso = null;
    });

    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    setState(() {
      _status = LeituraStatus.erro;
      _mensagemErro = _fase == _Fase.qrCode
          ? 'Não foi possível ler o QR Code. Certifique-se de que o código está visível e tente novamente.'
          : 'Falha ao ler o gabarito. Verifique se a folha está bem posicionada.';
    });
  }

  void _navegarParaCaptura() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CapturaProvasScreen(prova: widget.prova),
      ),
    );
  }

  /// Confirma cancelamento do fluxo.
  Future<bool> _confirmarCancelamento() async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar correção?'),
        content: const Text(
          'Se sair agora, o progresso da leitura será perdido.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Continuar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
    return resultado ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isQr = _fase == _Fase.qrCode;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final sair = await _confirmarCancelamento();
        if (sair && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.prova.titulo),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              final sair = await _confirmarCancelamento();
              if (sair && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
        body: Column(
          children: [
            // Indicador de progresso das fases
            _buildProgressIndicator(theme, colorScheme),

            // Câmera simulada
            Expanded(
              child: CameraPlaceholder(
                titulo: isQr
                    ? 'Aponte para o QR Code da prova'
                    : 'Aponte para o gabarito',
                descricao: isQr
                    ? 'O QR Code identifica a variante da prova.'
                    : 'Posicione a folha de gabarito dentro da moldura.',
                status: _status,
                mensagemErro: _mensagemErro,
                mensagemSucesso: _mensagemSucesso,
                onSimularSucesso:
                    _status != LeituraStatus.processando
                        ? _simularSucesso
                        : null,
                onSimularErro:
                    _status != LeituraStatus.processando
                        ? _simularErro
                        : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Indicador visual de qual fase está ativa (QR → Gabarito).
  Widget _buildProgressIndicator(ThemeData theme, ColorScheme colorScheme) {
    final isQr = _fase == _Fase.qrCode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // Step 1: QR
          _buildStep(
            theme: theme,
            colorScheme: colorScheme,
            label: 'QR Code',
            numero: 1,
            ativo: isQr,
            concluido: !isQr,
          ),

          // Linha conectora
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: !isQr
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
            ),
          ),

          // Step 2: Gabarito
          _buildStep(
            theme: theme,
            colorScheme: colorScheme,
            label: 'Gabarito',
            numero: 2,
            ativo: !isQr,
            concluido: false,
          ),
        ],
      ),
    );
  }

  Widget _buildStep({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required String label,
    required int numero,
    required bool ativo,
    required bool concluido,
  }) {
    final Color bgColor;
    final Color fgColor;

    if (concluido) {
      bgColor = colorScheme.primary;
      fgColor = colorScheme.onPrimary;
    } else if (ativo) {
      bgColor = colorScheme.primaryContainer;
      fgColor = colorScheme.onPrimaryContainer;
    } else {
      bgColor = colorScheme.surfaceContainerHighest;
      fgColor = colorScheme.onSurfaceVariant;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: concluido
                ? Icon(Icons.check, size: 16, color: fgColor)
                : Text(
                    '$numero',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: fgColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: ativo || concluido
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
            fontWeight: ativo ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
