import 'package:flutter/material.dart';

import 'models/correcao_models.dart';
import 'widgets/camera_placeholder.dart';
import 'resultado_correcao_screen.dart';

/// Tela de captura contínua de provas dos alunos (Step 3).
///
/// Simula o escaneamento sequencial das folhas de resposta.
/// Exibe um contador de progresso e permite simular sucesso/erro
/// a cada "scan". O professor pode finalizar quando quiser
/// (desde que ao menos 1 prova tenha sido escaneada).
class CapturaProvasScreen extends StatefulWidget {
  const CapturaProvasScreen({super.key, required this.prova});

  final ProvaCorrecao prova;

  @override
  State<CapturaProvasScreen> createState() => _CapturaProvasScreenState();
}

class _CapturaProvasScreenState extends State<CapturaProvasScreen> {
  LeituraStatus _status = LeituraStatus.aguardando;
  String? _mensagemErro;
  String? _mensagemSucesso;

  int _provasLidas = 0;
  int _errosLeitura = 0;

  /// Simula leitura bem-sucedida de uma prova.
  Future<void> _simularSucesso() async {
    setState(() {
      _status = LeituraStatus.processando;
      _mensagemErro = null;
      _mensagemSucesso = null;
    });

    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    _provasLidas++;

    setState(() {
      _status = LeituraStatus.sucesso;
      _mensagemSucesso =
          'Prova $_provasLidas lida com sucesso! '
          'Posicione a próxima folha.';
    });

    // Volta ao estado aguardando para próxima leitura
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    setState(() {
      _status = LeituraStatus.aguardando;
      _mensagemSucesso = null;
    });
  }

  /// Simula falha na leitura.
  Future<void> _simularErro() async {
    setState(() {
      _status = LeituraStatus.processando;
      _mensagemErro = null;
      _mensagemSucesso = null;
    });

    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    _errosLeitura++;

    setState(() {
      _status = LeituraStatus.erro;
      _mensagemErro =
          'Não foi possível ler a prova. '
          'Reposicione a folha e tente novamente.';
    });
  }

  /// Finaliza a captura e navega para os resultados.
  void _finalizar() {
    final resultados = gerarResultadosMock(
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

  /// Confirma cancelamento.
  Future<bool> _confirmarCancelamento() async {
    final msg = _provasLidas > 0
        ? 'Você já escaneou $_provasLidas prova(s). '
            'Se sair agora, esse progresso será perdido.'
        : 'Se sair agora, a correção será cancelada.';

    final resultado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar captura?'),
        content: Text(msg),
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final sair = await _confirmarCancelamento();
        if (sair && context.mounted) {
          // Volta até a seleção de prova
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Captura de Provas'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              final sair = await _confirmarCancelamento();
              if (sair && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            if (_provasLidas > 0)
              TextButton.icon(
                onPressed: _status != LeituraStatus.processando
                    ? _finalizar
                    : null,
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Finalizar'),
              ),
          ],
        ),
        body: CameraPlaceholder(
          titulo: 'Escaneie as provas dos alunos',
          descricao:
              'Posicione cada folha de resposta na câmera, uma por vez.',
          status: _status,
          mensagemErro: _mensagemErro,
          mensagemSucesso: _mensagemSucesso,
          onSimularSucesso:
              _status != LeituraStatus.processando ? _simularSucesso : null,
          onSimularErro:
              _status != LeituraStatus.processando ? _simularErro : null,
          child: _buildProgresso(theme, colorScheme),
        ),
      ),
    );
  }

  /// Barra de progresso com contadores.
  Widget _buildProgresso(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Provas lidas
              _buildContador(
                theme: theme,
                colorScheme: colorScheme,
                icon: Icons.check_circle_outline,
                valor: _provasLidas,
                label: 'Lidas',
                cor: colorScheme.primary,
              ),

              // Separador
              Container(
                width: 1,
                height: 32,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: colorScheme.outlineVariant,
              ),

              // Erros
              _buildContador(
                theme: theme,
                colorScheme: colorScheme,
                icon: Icons.error_outline,
                valor: _errosLeitura,
                label: 'Erros',
                cor: _errosLeitura > 0 ? colorScheme.error : colorScheme.onSurfaceVariant,
              ),

              // Separador
              Container(
                width: 1,
                height: 32,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: colorScheme.outlineVariant,
              ),

              // Restantes (estimativa)
              _buildContador(
                theme: theme,
                colorScheme: colorScheme,
                icon: Icons.people_outline,
                valor: (widget.prova.totalAlunos - _provasLidas)
                    .clamp(0, widget.prova.totalAlunos),
                label: 'Restantes',
                cor: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContador({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required IconData icon,
    required int valor,
    required String label,
    required Color cor,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: cor),
              const SizedBox(width: 4),
              Text(
                '$valor',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
