import '../../../features/correction/data/submission_repository.dart';

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
    this.classId,
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
  final String? classId;
}

/// Resultado de uma prova escaneada de um aluno.
class ResultadoAluno {
  const ResultadoAluno({
    required this.nomeAluno,
    required this.acertos,
    required this.totalQuestoes,
    this.erro = false,
    this.studentId,
    this.answers,
  });

  final String nomeAluno;
  final int acertos;
  final int totalQuestoes;
  final bool erro;
  final String? studentId;
  final List<SubmissionQuestionAnswer>? answers;

  double get percentual =>
      totalQuestoes > 0 ? (acertos / totalQuestoes) * 100 : 0;

  String get nota => '$acertos/$totalQuestoes';
}

/// Enum para estados da simulação de leitura.
enum LeituraStatus { aguardando, processando, sucesso, erro }

/// Gera a lista mockada de provas disponíveis para correção (fallback/testes).
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
  ];

  final resultados = <ResultadoAluno>[];
  for (int i = 0; i < totalAlunos && i < nomes.length; i++) {
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
