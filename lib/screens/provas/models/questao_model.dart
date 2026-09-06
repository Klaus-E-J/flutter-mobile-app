/// Modelo de dados para uma alternativa de questão.
///
/// Cada alternativa possui um [id] único, o [texto] da alternativa e um
/// indicador [correta] para marcar se ela é a resposta correta.
class Alternativa {
  Alternativa({
    required this.id,
    required this.texto,
    this.correta = false,
  });

  final String id;
  String texto;
  bool correta;

  Alternativa copyWith({String? texto, bool? correta}) {
    return Alternativa(
      id: id,
      texto: texto ?? this.texto,
      correta: correta ?? this.correta,
    );
  }
}

/// Modelo de dados para uma questão de prova.
///
/// Contém [enunciado], uma lista de [alternativas] e métodos auxiliares
/// para validação e manipulação dos dados.
class Questao {
  Questao({
    required this.id,
    this.enunciado = '',
    List<Alternativa>? alternativas,
  }) : alternativas = alternativas ?? [];

  final String id;
  String enunciado;
  List<Alternativa> alternativas;

  /// Número mínimo de alternativas que uma questão deve ter.
  static const int minimoAlternativas = 2;

  /// Número máximo de alternativas que uma questão pode ter.
  static const int maximoAlternativas = 6;

  /// Retorna a alternativa marcada como correta, ou `null` se nenhuma
  /// alternativa estiver marcada.
  Alternativa? get alternativaCorreta {
    try {
      return alternativas.firstWhere((a) => a.correta);
    } catch (_) {
      return null;
    }
  }

  /// Valida a questão e retorna uma lista de mensagens de erro.
  /// Retorna uma lista vazia se a questão estiver válida.
  List<String> validar() {
    final erros = <String>[];

    if (enunciado.trim().isEmpty) {
      erros.add('O enunciado não pode ser vazio.');
    }

    if (alternativas.length < minimoAlternativas) {
      erros.add(
        'A questão deve ter no mínimo $minimoAlternativas alternativas.',
      );
    }

    final alternativasVazias =
        alternativas.where((a) => a.texto.trim().isEmpty).toList();
    if (alternativasVazias.isNotEmpty) {
      erros.add(
        '${alternativasVazias.length} alternativa(s) com texto vazio.',
      );
    }

    final corretas = alternativas.where((a) => a.correta).length;
    if (corretas == 0) {
      erros.add('Marque exatamente uma alternativa como correta.');
    } else if (corretas > 1) {
      erros.add('Apenas uma alternativa pode ser marcada como correta.');
    }

    return erros;
  }

  /// Indica se a questão é válida (sem erros de validação).
  bool get isValid => validar().isEmpty;

  Questao copyWith({
    String? enunciado,
    List<Alternativa>? alternativas,
  }) {
    return Questao(
      id: id,
      enunciado: enunciado ?? this.enunciado,
      alternativas: alternativas ?? this.alternativas,
    );
  }
}

/// Gera um ID único simples baseado em timestamp + contador.
class IdGenerator {
  static int _counter = 0;

  static String generate() {
    _counter++;
    return '${DateTime.now().millisecondsSinceEpoch}_$_counter';
  }
}

/// Cria uma questão vazia com alternativas iniciais padrão (A e B).
Questao criarQuestaoVazia() {
  return Questao(
    id: IdGenerator.generate(),
    alternativas: [
      Alternativa(id: IdGenerator.generate(), texto: ''),
      Alternativa(id: IdGenerator.generate(), texto: ''),
    ],
  );
}

/// Cria uma lista de questões mockadas para demonstração.
List<Questao> criarQuestoesMock() {
  return [
    Questao(
      id: IdGenerator.generate(),
      enunciado: 'Qual é a capital do Brasil?',
      alternativas: [
        Alternativa(
          id: IdGenerator.generate(),
          texto: 'São Paulo',
        ),
        Alternativa(
          id: IdGenerator.generate(),
          texto: 'Rio de Janeiro',
        ),
        Alternativa(
          id: IdGenerator.generate(),
          texto: 'Brasília',
          correta: true,
        ),
        Alternativa(
          id: IdGenerator.generate(),
          texto: 'Salvador',
        ),
      ],
    ),
    Questao(
      id: IdGenerator.generate(),
      enunciado: 'Quanto é 2 + 2?',
      alternativas: [
        Alternativa(id: IdGenerator.generate(), texto: '3'),
        Alternativa(
          id: IdGenerator.generate(),
          texto: '4',
          correta: true,
        ),
        Alternativa(id: IdGenerator.generate(), texto: '5'),
      ],
    ),
  ];
}
