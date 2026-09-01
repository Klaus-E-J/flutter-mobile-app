// Modelos de dados mockados para o fluxo de correção.
//
// Estes modelos são exclusivos do módulo de correção e não dependem
// de nenhum outro módulo (FE-06/07). Os dados vivem e morrem aqui.

/// Representa uma prova disponível para correção.
class ProvaCorrecao {
  const ProvaCorrecao({
    required this.id,
    required this.titulo,
    required this.turma,
    required this.disciplina,
    required this.totalQuestoes,
    required this.totalAlunos,
    this.provaIndividual = false,
    this.dataCriacao,
  });

  final String id;
  final String titulo;
  final String turma;
  final String disciplina;
  final int totalQuestoes;
  final int totalAlunos;

  /// Se `true`, cada aluno tem uma sequência diferente de questões
  /// e o QR Code precisa ser lido antes de cada gabarito.
  /// Se `false`, a sequência é a mesma para todos (QR lido uma vez).
  final bool provaIndividual;

  final DateTime? dataCriacao;
}

/// Resultado mockado de uma prova escaneada de um aluno.
class ResultadoAluno {
  const ResultadoAluno({
    required this.nomeAluno,
    required this.acertos,
    required this.totalQuestoes,
    this.erro = false,
  });

  final String nomeAluno;
  final int acertos;
  final int totalQuestoes;
  final bool erro;

  double get percentual =>
      totalQuestoes > 0 ? (acertos / totalQuestoes) * 100 : 0;

  String get nota => '$acertos/$totalQuestoes';
}

/// Enum para estados da simulação de leitura.
enum LeituraStatus { aguardando, processando, sucesso, erro }

/// Gera a lista mockada de provas disponíveis para correção.
List<ProvaCorrecao> gerarProvasMock() {
  return [
    ProvaCorrecao(
      id: '1',
      titulo: 'Prova 1 - Matemática',
      turma: '9º Ano A',
      disciplina: 'Matemática',
      totalQuestoes: 10,
      totalAlunos: 35,
      dataCriacao: DateTime(2026, 8, 20),
    ),
    ProvaCorrecao(
      id: '2',
      titulo: 'Prova 2 - Português',
      turma: '8º Ano B',
      disciplina: 'Português',
      totalQuestoes: 15,
      totalAlunos: 28,
      provaIndividual: true,
      dataCriacao: DateTime(2026, 8, 25),
    ),
    ProvaCorrecao(
      id: '3',
      titulo: 'Simulado Bimestral',
      turma: '7º Ano C',
      disciplina: 'Ciências',
      totalQuestoes: 20,
      totalAlunos: 42,
      provaIndividual: true,
      dataCriacao: DateTime(2026, 8, 28),
    ),
    ProvaCorrecao(
      id: '4',
      titulo: 'Avaliação Diagnóstica',
      turma: '6º Ano A',
      disciplina: 'História',
      totalQuestoes: 12,
      totalAlunos: 30,
      dataCriacao: DateTime(2026, 8, 30),
    ),
  ];
}

/// Gera resultados mockados de alunos para a tela de resultados.
List<ResultadoAluno> gerarResultadosMock(int totalAlunos, int totalQuestoes) {
  final nomes = [
    'Ana Silva',
    'Bruno Costa',
    'Carla Souza',
    'Diego Oliveira',
    'Elena Santos',
    'Felipe Mendes',
    'Gabriela Lima',
    'Hugo Pereira',
    'Isabela Rocha',
    'João Ferreira',
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

  final resultados = <ResultadoAluno>[];
  for (int i = 0; i < totalAlunos && i < nomes.length; i++) {
    // Simula acertos variados (entre 40% e 100%)
    final fator = 0.4 + (i % 7) * 0.1;
    final acertos = (totalQuestoes * fator).round().clamp(0, totalQuestoes);

    resultados.add(ResultadoAluno(
      nomeAluno: nomes[i],
      acertos: acertos,
      totalQuestoes: totalQuestoes,
    ));
  }

  return resultados;
}
