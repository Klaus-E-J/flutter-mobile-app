import 'package:flutter/material.dart';

// ============================================================================
// DATA MODELS
// ============================================================================

/// Representa uma alternativa/opção de resposta para uma questão
class Alternativa {
  final String id;
  final String texto;

  Alternativa({
    required this.id,
    required this.texto,
  });

  Alternativa copyWith({
    String? id,
    String? texto,
  }) {
    return Alternativa(
      id: id ?? this.id,
      texto: texto ?? this.texto,
    );
  }
}

/// Representa uma questão da prova
class Questao {
  final String id;
  final String enunciado;
  final List<Alternativa> alternativas;
  final int indiceCorreto; // Índice da alternativa correta (0-based)

  Questao({
    required this.id,
    required this.enunciado,
    required this.alternativas,
    required this.indiceCorreto,
  });

  Questao copyWith({
    String? id,
    String? enunciado,
    List<Alternativa>? alternativas,
    int? indiceCorreto,
  }) {
    return Questao(
      id: id ?? this.id,
      enunciado: enunciado ?? this.enunciado,
      alternativas: alternativas ?? this.alternativas,
      indiceCorreto: indiceCorreto ?? this.indiceCorreto,
    );
  }
}

// ============================================================================
// MAIN SCREEN
// ============================================================================

class ProvaQuestoesScreen extends StatefulWidget {
  final String provaId;
  final String provaNome;

  const ProvaQuestoesScreen({
    super.key,
    required this.provaId,
    required this.provaNome,
  });

  @override
  State<ProvaQuestoesScreen> createState() => _ProvaQuestoesScreenState();
}

class _ProvaQuestoesScreenState extends State<ProvaQuestoesScreen> {
  // Dados mockados: lista de questões da prova
  late List<Questao> questoes;

  // Estado para controlar mensagens de erro
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeMockedData();
  }

  /// Inicializa os dados mockados da prova
  void _initializeMockedData() {
    questoes = [
      // Questão exemplo 1
      Questao(
        id: '1',
        enunciado: 'Qual é a capital do Brasil?',
        alternativas: [
          Alternativa(id: 'a', texto: 'São Paulo'),
          Alternativa(id: 'b', texto: 'Rio de Janeiro'),
          Alternativa(id: 'c', texto: 'Brasília'),
          Alternativa(id: 'd', texto: 'Belo Horizonte'),
        ],
        indiceCorreto: 2, // Brasília
      ),
    ];
  }

  /// Abre dialog para adicionar nova questão
  void _showAddQuestionDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddEditQuestionDialog(
        questao: null,
        onSave: (questao) {
          _addQuestao(questao);
          Navigator.pop(context);
        },
      ),
    );
  }

  /// Abre dialog para editar questão existente
  void _showEditQuestionDialog(Questao questao) {
    showDialog(
      context: context,
      builder: (context) => _AddEditQuestionDialog(
        questao: questao,
        onSave: (questaoAtualizada) {
          _editQuestao(questao.id, questaoAtualizada);
          Navigator.pop(context);
        },
      ),
    );
  }

  /// Adiciona uma nova questão à lista
  void _addQuestao(Questao questao) {
    setState(() {
      _errorMessage = null;
      questoes.add(questao);
    });
  }

  /// Edita uma questão existente
  void _editQuestao(String questaoId, Questao questaoAtualizada) {
    setState(() {
      _errorMessage = null;
      final index = questoes.indexWhere((q) => q.id == questaoId);
      if (index != -1) {
        questoes[index] = questaoAtualizada;
      }
    });
  }

  /// Remove uma questão da lista
  void _deleteQuestao(String questaoId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Questão'),
        content: const Text(
          'Deseja remover esta questão? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                questoes.removeWhere((q) => q.id == questaoId);
                _errorMessage = null;
              });
              Navigator.pop(context);
            },
            child: const Text(
              'Remover',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.provaNome} - Questões'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Exibe mensagem de erro se houver
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Material(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() => _errorMessage = null);
                        },
                        icon: Icon(Icons.close, color: Colors.red.shade700),
                        iconSize: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Estado vazio
          if (questoes.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nenhuma questão adicionada',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Toque no botão abaixo para adicionar a primeira questão',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            // Lista de questões
            Expanded(
              child: ListView.builder(
                itemCount: questoes.length,
                padding: const EdgeInsets.all(12),
                itemBuilder: (context, index) {
                  final questao = questoes[index];
                  return _QuestaoCard(
                    questao: questao,
                    numeroQuestao: index + 1,
                    onEdit: () => _showEditQuestionDialog(questao),
                    onDelete: () => _deleteQuestao(questao.id),
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddQuestionDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ============================================================================
// WIDGET: QUESTÃO CARD
// ============================================================================

class _QuestaoCard extends StatelessWidget {
  final Questao questao;
  final int numeroQuestao;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _QuestaoCard({
    required this.questao,
    required this.numeroQuestao,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho: número, enunciado e ações
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Número da questão
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    'Q$numeroQuestao',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Enunciado
                Expanded(
                  child: Text(
                    questao.enunciado,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Botões de ação
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'Remover',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Alternativas
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: questao.alternativas.length,
              itemBuilder: (context, index) {
                final alternativa = questao.alternativas[index];
                final isCorreta = index == questao.indiceCorreto;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _AlternativaDisplay(
                    alternativa: alternativa,
                    isCorreta: isCorreta,
                    letra: String.fromCharCode(65 + index), // A, B, C, D...
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// WIDGET: ALTERNATIVA DISPLAY
// ============================================================================

class _AlternativaDisplay extends StatelessWidget {
  final Alternativa alternativa;
  final bool isCorreta;
  final String letra;

  const _AlternativaDisplay({
    required this.alternativa,
    required this.isCorreta,
    required this.letra,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$letra) ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isCorreta ? Colors.green.shade700 : Colors.grey.shade600,
          ),
        ),
        Expanded(
          child: Text(
            alternativa.texto,
            style: TextStyle(
              fontSize: 12,
              color: isCorreta ? Colors.green.shade700 : Colors.grey.shade700,
              fontWeight: isCorreta ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        if (isCorreta)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Icon(
              Icons.check_circle,
              size: 16,
              color: Colors.green.shade700,
            ),
          ),
      ],
    );
  }
}

// ============================================================================
// DIALOG: ADD/EDIT QUESTION
// ============================================================================

class _AddEditQuestionDialog extends StatefulWidget {
  final Questao? questao;
  final Function(Questao) onSave;

  const _AddEditQuestionDialog({
    required this.questao,
    required this.onSave,
  });

  @override
  State<_AddEditQuestionDialog> createState() => _AddEditQuestionDialogState();
}

class _AddEditQuestionDialogState extends State<_AddEditQuestionDialog> {
  late TextEditingController _enunciadoController;
  late List<TextEditingController> _alternativaControllers;
  late int _indiceCorrecto;
  String? _validationError;

  static const int _minAlternativas = 2;
  static const int _maxAlternativas = 5;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    if (widget.questao != null) {
      // Editando uma questão existente
      _enunciadoController =
          TextEditingController(text: widget.questao!.enunciado);
      _alternativaControllers = widget.questao!.alternativas
          .map((alt) => TextEditingController(text: alt.texto))
          .toList();
      _indiceCorrecto = widget.questao!.indiceCorreto;
    } else {
      // Criando uma nova questão
      _enunciadoController = TextEditingController();
      _alternativaControllers = [
        TextEditingController(),
        TextEditingController(),
      ];
      _indiceCorrecto = 0;
    }
  }

  @override
  void dispose() {
    _enunciadoController.dispose();
    for (var controller in _alternativaControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Valida os dados da questão
  bool _validate() {
    if (_enunciadoController.text.trim().isEmpty) {
      _setError('O enunciado da questão não pode ser vazio');
      return false;
    }

    final alternativasPreen = _alternativaControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (alternativasPreen.length < _minAlternativas) {
      _setError(
        'Mínimo de $_minAlternativas alternativas preenchidas necessárias',
      );
      return false;
    }

    if (_indiceCorrecto >= alternativasPreen.length) {
      _setError('Selecione uma alternativa correta válida');
      return false;
    }

    _clearError();
    return true;
  }

  void _setError(String message) {
    setState(() => _validationError = message);
  }

  void _clearError() {
    setState(() => _validationError = null);
  }

  void _addAlternativa() {
    if (_alternativaControllers.length < _maxAlternativas) {
      setState(() {
        _alternativaControllers.add(TextEditingController());
      });
    }
  }

  void _removeAlternativa(int index) {
    setState(() {
      _alternativaControllers[index].dispose();
      _alternativaControllers.removeAt(index);
      if (_indiceCorrecto == index) {
        _indiceCorrecto = 0;
      } else if (_indiceCorrecto > index) {
        _indiceCorrecto--;
      }
    });
  }

  void _save() {
    if (!_validate()) return;

    // Coleta as alternativas preenchidas
    final alternativas = _alternativaControllers
        .map((controller) => controller.text.trim())
        .where((texto) => texto.isNotEmpty)
        .map((texto) => Alternativa(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              texto: texto,
            ))
        .toList();

    final novaQuestao = Questao(
      id: widget.questao?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      enunciado: _enunciadoController.text.trim(),
      alternativas: alternativas,
      indiceCorreto: _indiceCorrecto,
    );

    widget.onSave(novaQuestao);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              Text(
                widget.questao == null
                    ? 'Nova Questão'
                    : 'Editar Questão',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Mensagem de erro
              if (_validationError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: Colors.red.shade700, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _validationError!,
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Campo: Enunciado
              Text(
                'Enunciado',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _enunciadoController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Digite o enunciado da questão...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
                onChanged: (_) => _clearError(),
              ),
              const SizedBox(height: 20),

              // Seção de alternativas
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Alternativas',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  if (_alternativaControllers.length < _maxAlternativas)
                    TextButton.icon(
                      onPressed: _addAlternativa,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Adicionar', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Lista de alternativas
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _alternativaControllers.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AlternativaInput(
                      index: index,
                      controller: _alternativaControllers[index],
                      letra: String.fromCharCode(65 + index),
                      isCorreta: _indiceCorrecto == index,
                      onCorrectChanged: (isCorreta) {
                        setState(() {
                          if (isCorreta) {
                            _indiceCorrecto = index;
                          }
                        });
                      },
                      onRemove: () => _removeAlternativa(index),
                      canRemove: _alternativaControllers.length >
                          _minAlternativas,
                      onChanged: (_) => _clearError(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Botões de ação
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _save,
                    child: Text(
                      widget.questao == null ? 'Adicionar' : 'Salvar',
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

// ============================================================================
// WIDGET: ALTERNATIVA INPUT
// ============================================================================

class _AlternativaInput extends StatelessWidget {
  final int index;
  final TextEditingController controller;
  final String letra;
  final bool isCorreta;
  final Function(bool) onCorrectChanged;
  final VoidCallback onRemove;
  final bool canRemove;
  final Function(String) onChanged;

  const _AlternativaInput({
    required this.index,
    required this.controller,
    required this.letra,
    required this.isCorreta,
    required this.onCorrectChanged,
    required this.onRemove,
    required this.canRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Letra
        Text(
          '$letra)',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        // Campo de texto
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Alternativa $letra',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onCorrectChanged(!isCorreta),
                  child: Tooltip(
                    message: 'Marcar como correta',
                    child: Icon(
                      isCorreta
                          ? Icons.check_circle
                          : Icons.check_circle_outline,
                      color: isCorreta ? Colors.green : Colors.grey,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 8),
        // Botão remover
        if (canRemove)
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            onPressed: onRemove,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
      ],
    );
  }
}
