import 'package:flutter/material.dart';

import 'models/correcao_models.dart';
import 'widgets/camera_placeholder.dart';
import 'leitura_qr_screen.dart';
import 'resultado_correcao_screen.dart';

/// Nomes mockados de alunos para exibição durante a captura.
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
///
/// Captura folhas de resposta estilo ENEM.
///
/// **Prova normal** (`provaIndividual == false`):
///   Captura contínua — todas as folhas uma após a outra.
///
/// **Prova individual** (`provaIndividual == true`):
///   Captura UMA folha, depois volta para [LeituraQrScreen]
///   para ler o QR do próximo aluno antes do próximo gabarito.
class LeituraGabaritoScreen extends StatefulWidget {
  const LeituraGabaritoScreen({
    super.key,
    required this.prova,
    this.provasLidas = 0,
    this.errosLeitura = 0,
  });

  final ProvaCorrecao prova;

  /// Progresso acumulado (para loop de prova individual).
  final int provasLidas;
  final int errosLeitura;

  @override
  State<LeituraGabaritoScreen> createState() => _LeituraGabaritoScreenState();
}

class _LeituraGabaritoScreenState extends State<LeituraGabaritoScreen> {
  LeituraStatus _status = LeituraStatus.aguardando;
  String? _feedbackText;
  bool _feedbackIsError = false;

  late int _provasLidas;
  late int _errosLeitura;

  @override
  void initState() {
    super.initState();
    _provasLidas = widget.provasLidas;
    _errosLeitura = widget.errosLeitura;
  }

  /// Nome do aluno atual (mock).
  String get _alunoAtual {
    final index = _provasLidas % _nomesMock.length;
    return _nomesMock[index];
  }

  /// Simula captura bem-sucedida de um gabarito.
  Future<void> _capturar() async {
    setState(() {
      _status = LeituraStatus.processando;
      _feedbackText = null;
    });

    await Future<void>.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    final nomeCapturado =
        _nomesMock[_provasLidas % _nomesMock.length];
    _provasLidas++;

    setState(() {
      _status = LeituraStatus.sucesso;
      _feedbackText = 'Gabarito de $nomeCapturado registrado';
      _feedbackIsError = false;
    });

    await Future<void>.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    // Prova individual: volta para QR do próximo aluno
    if (widget.prova.provaIndividual) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LeituraQrScreen(
            prova: widget.prova,
            provasLidas: _provasLidas,
            errosLeitura: _errosLeitura,
          ),
        ),
      );
      return;
    }

    // Prova normal: continua capturando
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

  /// Finaliza a captura e navega para resultados.
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

  Future<void> _confirmarCancelamento() async {
    final msg = _provasLidas > 0
        ? 'Você já capturou $_provasLidas gabarito(s). '
            'Se sair agora, esse progresso será perdido.'
        : 'Se sair agora, a correção será cancelada.';

    final sair = await showDialog<bool>(
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
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Título
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

              // Câmera simulada
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

              // Contador — "Prova X de Y"
              Text(
                'Prova ${_provasLidas + 1} de ${widget.prova.totalAlunos}',
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

              // Feedback
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
                  child: const Text('Capturar prova'),
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
