import 'package:flutter/material.dart';

import '../../core/widgets/app_widgets.dart';
import 'models/questao_model.dart';
import 'widgets/questao_card.dart';

/// Tela de edição das questões dentro de uma prova (FE-07).
///
/// Permite adicionar, editar e remover questões de uma prova.
/// Os dados são mantidos localmente (mockados) dentro do contexto
/// desta tela — não há integração com API nesta versão.
///
/// ## Estados da UI:
/// - **Carregamento**: Breve simulação de loading inicial (mock).
/// - **Vazio**: Quando não há questões cadastradas.
/// - **Lista preenchida**: Quando há uma ou mais questões.
/// - **Erro de validação**: Quando o usuário tenta salvar/validar
///   com questões inválidas.
class ProvaQuestoesScreen extends StatefulWidget {
  const ProvaQuestoesScreen({
    super.key,
    this.provaTitulo = 'Prova sem título',
    this.questoesIniciais,
  });

  /// Título da prova sendo editada (para exibição na AppBar).
  final String provaTitulo;

  /// Questões iniciais opcionais. Se `null`, inicia com lista vazia.
  /// Se passado, as questões são copiadas para o estado local.
  final List<Questao>? questoesIniciais;

  @override
  State<ProvaQuestoesScreen> createState() => _ProvaQuestoesScreenState();
}

class _ProvaQuestoesScreenState extends State<ProvaQuestoesScreen> {
  /// Lista de questões da prova (estado local, vive e morre aqui).
  List<Questao> _questoes = [];

  /// Indica se está "carregando" dados (simulação mock).
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

  /// Simula um breve carregamento e inicializa os dados.
  Future<void> _carregarDados() async {
    // Simula latência de carregamento para demonstrar o estado de loading
    await Future<void>.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    setState(() {
      _questoes = widget.questoesIniciais ?? [];
      _isLoading = false;
    });
  }

  /// Adiciona uma nova questão vazia ao final da lista.
  void _adicionarQuestao() {
    setState(() {
      _questoes.add(criarQuestaoVazia());
      _temAlteracoes = true;
      _erroGlobal = null;
    });
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

  /// Carrega questões mockadas de exemplo.
  void _carregarMock() {
    setState(() {
      _questoes = criarQuestoesMock();
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

  /// Simula o "salvar" das questões da prova.
  void _salvar() {
    if (!_validarTudo()) return;

    // Nesta versão mock, apenas mostra feedback de sucesso
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${_questoes.length} questão(ões) salva(s) com sucesso!',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );

    setState(() {
      _temAlteracoes = false;
      _erroGlobal = null;
    });

    // Em produção: Navigator.pop(context, _questoes);
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
                'Adicione questões à prova usando o botão abaixo '
                'ou carregue um exemplo para começar.',
            action: OutlinedButton.icon(
              onPressed: _carregarMock,
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('Carregar exemplo'),
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
          child: Row(
            children: [
              Icon(
                Icons.quiz_outlined,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '${_questoes.length} questão(ões)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              // Botão de validação geral
              TextButton.icon(
                onPressed: _validarTudo,
                icon: const Icon(Icons.playlist_add_check, size: 18),
                label: const Text('Validar tudo'),
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
