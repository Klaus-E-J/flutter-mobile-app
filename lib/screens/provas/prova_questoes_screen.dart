import 'package:flutter/material.dart';

import '../../core/widgets/app_widgets.dart';
import '../../features/exams/data/exam_repository.dart';
import 'models/questao_model.dart';
import 'widgets/questao_card.dart';

/// Tela de edição das questões dentro de uma prova (FE-07).
///
/// Permite adicionar, editar, remover e persistir questões de uma prova.
///
/// ## Estados da UI:
/// - **Carregamento**: consulta ao Firestore.
/// - **Vazio**: Quando não há questões cadastradas.
/// - **Lista preenchida**: Quando há uma ou mais questões.
/// - **Erro de validação**: Quando o usuário tenta salvar/validar
///   com questões inválidas.
class ProvaQuestoesScreen extends StatefulWidget {
  const ProvaQuestoesScreen({
    super.key,
    required this.examId,
    this.provaTitulo = 'Prova sem título',
    this.initialQuestions,
    this.openQuickAnswerKeyOnStart = false,
  });

  final String examId;
  final String provaTitulo;
  final List<Questao>? initialQuestions;
  final bool openQuickAnswerKeyOnStart;

  @override
  State<ProvaQuestoesScreen> createState() => _ProvaQuestoesScreenState();
}

class _ProvaQuestoesScreenState extends State<ProvaQuestoesScreen> {
  final ExamRepository _repository = ExamRepository();
  List<Questao> _questoes = [];

  /// Indica se uma operação de carregamento ou gravação está em andamento.
  bool _isLoading = true;

  /// Mensagem de erro global (ex.: validação geral ao salvar).
  String? _erroGlobal;

  /// Flag que indica se houve alterações não salvas.
  bool _temAlteracoes = false;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    if (widget.initialQuestions != null) {
      setState(() {
        _questoes = List<Questao>.from(widget.initialQuestions!);
        _isLoading = false;
      });
      if (widget.openQuickAnswerKeyOnStart) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _abrirAssistenteGabaritoRapido();
        });
      }
      return;
    }

    try {
      final questions = await _repository.watchQuestions(widget.examId).first;
      if (!mounted) return;
      setState(() {
        _questoes = questions;
        _isLoading = false;
      });
      if (widget.openQuickAnswerKeyOnStart) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _abrirAssistenteGabaritoRapido();
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _erroGlobal = 'Não foi possível carregar as questões: $error';
      });
    }
  }

  /// Adiciona uma nova questão vazia ao final da lista, respeitando o limite de 30 questões por folha OMR.
  void _adicionarQuestao() {
    if (_questoes.length >= Questao.maximoQuestoesOmr) {
      setState(() {
        _erroGlobal =
            'Limite máximo de ${Questao.maximoQuestoesOmr} questões por folha de respostas OMR atingido.';
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'A folha de respostas OMR comporta no máximo 30 questões.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    setState(() {
      _questoes.add(criarQuestaoVazia());
      _temAlteracoes = true;
      _erroGlobal = null;
    });
  }

  /// Abre o assistente de "Gabarito Rápido (Prova Externa)" (requisito cliente §2).
  Future<void> _abrirAssistenteGabaritoRapido() async {
    final novasQuestoes = await showModalBottomSheet<List<Questao>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _GabaritoRapidoSheet(
        questoesAtuais: _questoes,
      ),
    );

    if (!mounted || novasQuestoes == null || novasQuestoes.isEmpty) return;

    setState(() {
      _questoes = novasQuestoes;
      _temAlteracoes = true;
      _erroGlobal = null;
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Gabarito rápido com ${novasQuestoes.length} questão(ões) gerado! Toque em Salvar para confirmar.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  /// Remove a questão no [index] dado.
  void _removerQuestao(int index) {
    setState(() {
      _questoes.removeAt(index);
      _temAlteracoes = true;
      _erroGlobal = null;
    });
  }

  /// Callback invocado quando qualquer questão é editada.
  void _onQuestaoChanged() {
    setState(() {
      _temAlteracoes = true;
      _erroGlobal = null;
    });
  }

  /// Valida todas as questões antes de "salvar".
  bool _validarTudo() {
    if (_questoes.isEmpty) {
      setState(() {
        _erroGlobal = 'Adicione ao menos uma questão à prova.';
      });
      return false;
    }

    if (_questoes.length > Questao.maximoQuestoesOmr) {
      setState(() {
        _erroGlobal =
            'A prova possui ${_questoes.length} questões, mas o limite máximo da folha OMR é de ${Questao.maximoQuestoesOmr} questões.';
      });
      return false;
    }

    final questoesInvalidas = <int>[];
    for (int i = 0; i < _questoes.length; i++) {
      if (!_questoes[i].isValid) {
        questoesInvalidas.add(i + 1);
      }
    }

    if (questoesInvalidas.isNotEmpty) {
      setState(() {
        _erroGlobal =
            'As seguintes questões possuem erros: '
            '${questoesInvalidas.join(', ')}. '
            'Corrija antes de salvar.';
      });
      return false;
    }

    return true;
  }

  /// Persiste as questões da prova no Cloud Firestore e sincroniza as variantes (N3-02).
  Future<void> _salvar() async {
    if (!_validarTudo()) return;
    setState(() => _isLoading = true);
    try {
      await _repository.saveQuestions(widget.examId, _questoes);
      try {
        await _repository.regenerateVariantsForExam(examId: widget.examId);
      } catch (_) {}
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_questoes.length} questão(ões) salva(s) no Firestore.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _temAlteracoes = false;
        _erroGlobal = null;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _erroGlobal = 'Não foi possível salvar as questões: $error';
      });
    }
  }

  /// Exibe confirmação antes de sair com alterações não salvas.
  Future<bool> _confirmarSaida() async {
    if (!_temAlteracoes) return true;

    final resultado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alterações não salvas'),
        content: const Text(
          'Você tem alterações não salvas. '
          'Deseja sair sem salvar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Continuar editando'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    return resultado ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_temAlteracoes,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final sair = await _confirmarSaida();
        if (sair && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.provaTitulo),
          actions: [
            if (!_isLoading)
              IconButton(
                onPressed: _abrirAssistenteGabaritoRapido,
                icon: const Icon(Icons.flash_on_outlined),
                tooltip: 'Gabarito Rápido (Prova Externa)',
              ),
            if (!_isLoading && _questoes.isNotEmpty)
              TextButton.icon(
                onPressed: _salvar,
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Salvar'),
              ),
          ],
        ),
        body: _buildBody(),
        floatingActionButton: !_isLoading
            ? FloatingActionButton.extended(
                onPressed: _adicionarQuestao,
                icon: const Icon(Icons.add),
                label: const Text('Questão'),
              )
            : null,
      ),
    );
  }

  Widget _buildBody() {
    // Estado de carregamento
    if (_isLoading) {
      return const AppLoading(message: 'Carregando questões...');
    }

    // Estado vazio
    if (_questoes.isEmpty) {
      return _buildEstadoVazio();
    }

    // Lista de questões
    return _buildListaQuestoes();
  }

  Widget _buildEstadoVazio() {
    return Column(
      children: [
        // Mensagem de erro global, se houver
        if (_erroGlobal != null) _buildErroGlobal(),

        Expanded(
          child: AppEmptyState(
            icon: Icons.quiz_outlined,
            title: 'Nenhuma questão cadastrada',
            description:
                'Adicione questões completas usando o botão abaixo ou gere apenas o Gabarito Rápido com QR Code para uma prova externa.',
            action: OutlinedButton.icon(
              onPressed: _abrirAssistenteGabaritoRapido,
              icon: const Icon(Icons.grid_on_outlined),
              label: const Text('Gabarito Rápido (Prova Externa)'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListaQuestoes() {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Mensagem de erro global, se houver
        if (_erroGlobal != null) _buildErroGlobal(),

        // Contagem e ações do topo
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.quiz_outlined,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_questoes.length}/${Questao.maximoQuestoesOmr} questão(ões)',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton.icon(
                    onPressed: _abrirAssistenteGabaritoRapido,
                    icon: const Icon(Icons.grid_on_outlined, size: 18),
                    label: const Text('Gabarito Rápido'),
                  ),
                  TextButton.icon(
                    onPressed: _validarTudo,
                    icon: const Icon(Icons.playlist_add_check, size: 18),
                    label: const Text('Validar tudo'),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 4),

        // Lista de cards de questão
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
            itemCount: _questoes.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final questao = _questoes[index];
              return QuestaoCard(
                key: ValueKey(questao.id),
                questao: questao,
                numero: index + 1,
                onChanged: _onQuestaoChanged,
                onRemover: () => _removerQuestao(index),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Banner de erro global exibido no topo da tela.
  Widget _buildErroGlobal() {
    final colorScheme = Theme.of(context).colorScheme;

    return MaterialBanner(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      content: Text(
        _erroGlobal!,
        style: TextStyle(color: colorScheme.onErrorContainer),
      ),
      leading: Icon(
        Icons.error_outline,
        color: colorScheme.error,
      ),
      backgroundColor: colorScheme.errorContainer.withValues(alpha: 0.4),
      actions: [
        TextButton(
          onPressed: () => setState(() => _erroGlobal = null),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}

/// Assistente modal para geração rápida de gabarito (Prova Externa já diagramada fora do app).
class _GabaritoRapidoSheet extends StatefulWidget {
  const _GabaritoRapidoSheet({
    required this.questoesAtuais,
  });

  final List<Questao> questoesAtuais;

  @override
  State<_GabaritoRapidoSheet> createState() => _GabaritoRapidoSheetState();
}

class _GabaritoRapidoSheetState extends State<_GabaritoRapidoSheet> {
  static const List<String> _letras = ['A', 'B', 'C', 'D', 'E'];

  late int _quantidade;
  late int _totalAlternativas;
  late final Map<int, String> _respostas;

  @override
  void initState() {
    super.initState();
    _quantidade = widget.questoesAtuais.isNotEmpty
        ? widget.questoesAtuais.length.clamp(1, Questao.maximoQuestoesOmr)
        : 10;
    _totalAlternativas = widget.questoesAtuais.isNotEmpty
        ? widget.questoesAtuais.first.alternativas.length.clamp(
            4,
            Questao.maximoAlternativas,
          )
        : Questao.maximoAlternativas;
    _respostas = <int, String>{};

    for (var i = 1; i <= Questao.maximoQuestoesOmr; i++) {
      if (i <= widget.questoesAtuais.length) {
        final q = widget.questoesAtuais[i - 1];
        final idxCorreta = q.alternativas.indexWhere((a) => a.correta);
        _respostas[i] =
            (idxCorreta >= 0 && idxCorreta < _letras.length) ? _letras[idxCorreta] : 'A';
      } else {
        _respostas[i] = 'A';
      }
    }
  }

  void _confirmar() {
    final letrasValidas = _letras.take(_totalAlternativas).toList();
    final geradas = List<Questao>.generate(
      _quantidade,
      (index) {
        final numero = index + 1;
        final rawLetra = _respostas[numero] ?? 'A';
        final letra =
            letrasValidas.contains(rawLetra) ? rawLetra : letrasValidas.first;
        return criarQuestaoGabaritoRapido(
          numero: numero,
          letraCorreta: letra,
          totalAlternativas: _totalAlternativas,
        );
      },
    );
    Navigator.of(context).pop(geradas);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final letrasVisiveis = _letras.take(_totalAlternativas).toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Gabarito Rápido (Prova Externa)',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Ideal para provas já formatadas fora do app. Defina o número de questões (1 a 30) e marque a alternativa correta de cada questão para gerar a Folha OMR com QR Code.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total de questões: ',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        tooltip: 'Diminuir questões',
                        onPressed: _quantidade > 1
                            ? () => setState(() => _quantidade--)
                            : null,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$_quantidade',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        tooltip: 'Aumentar questões',
                        onPressed: _quantidade < Questao.maximoQuestoesOmr
                            ? () => setState(() => _quantidade++)
                            : null,
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 6,
                    children: [5, 10, 15, 20, 30].map((preset) {
                      return ActionChip(
                        label: Text('$preset'),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => setState(() => _quantidade = preset),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  Text(
                    'Alternativas por questão:',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  ChoiceChip(
                    label: const Text('4 (A–D)'),
                    selected: _totalAlternativas == 4,
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) => setState(() => _totalAlternativas = 4),
                  ),
                  ChoiceChip(
                    label: const Text('5 (A–E)'),
                    selected: _totalAlternativas == 5,
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) => setState(() => _totalAlternativas = 5),
                  ),
                ],
              ),
              const Divider(height: 20),
              Expanded(
                child: ListView.separated(
                  itemCount: _quantidade,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final qNum = index + 1;
                    final rawSelecionada = _respostas[qNum] ?? 'A';
                    final selecionada = letrasVisiveis.contains(rawSelecionada)
                        ? rawSelecionada
                        : 'A';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 56,
                            child: Text(
                              'Q${qNum.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              children: letrasVisiveis.map((letra) {
                                final isSelected = selecionada == letra;
                                return ChoiceChip(
                                  label: Text(letra),
                                  selected: isSelected,
                                  visualDensity: VisualDensity.compact,
                                  onSelected: (_) {
                                    setState(() {
                                      _respostas[qNum] = letra;
                                    });
                                  },
                                );
                              }).toList(),
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
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _confirmar,
                      icon: const Icon(Icons.check),
                      label: const Text('Aplicar Gabarito'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
