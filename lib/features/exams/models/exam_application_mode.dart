/// Como a prova é aplicada aos alunos.
///
/// As questões e alternativas são sempre as mesmas; o modo só define o que
/// é embaralhado. Não há opções extras de embaralhamento na impressão.
enum ExamApplicationMode {
  /// Questões e alternativas em ordem diferente para cada aluno.
  individual(
    id: 'individual',
    label: 'Provas diferentes por aluno',
    description: 'Questões e alternativas embaralhadas para cada aluno.',
    perStudent: true,
    shuffleQuestions: true,
    shuffleAlternatives: true,
  ),

  /// Só a ordem das questões muda; alternativas ficam na ordem original.
  questionOrder(
    id: 'questionOrder',
    label: 'Sequência das questões diferente por aluno',
    description: 'Só as questões são embaralhadas para cada aluno.',
    perStudent: true,
    shuffleQuestions: true,
    shuffleAlternatives: false,
  ),

  /// Só a ordem das alternativas muda; questões ficam na ordem original.
  answerOrder(
    id: 'answerOrder',
    label: 'Sequência das respostas diferente por aluno',
    description: 'Só as alternativas são embaralhadas para cada aluno.',
    perStudent: true,
    shuffleQuestions: false,
    shuffleAlternatives: true,
  ),

  /// Prova idêntica para todos, sem embaralhamento.
  sameForEveryone(
    id: 'sameForEveryone',
    label: 'Mesma prova para todos os alunos',
    description: 'Nada é embaralhado.',
    perStudent: false,
    shuffleQuestions: false,
    shuffleAlternatives: false,
  );

  const ExamApplicationMode({
    required this.id,
    required this.label,
    required this.description,
    required this.perStudent,
    required this.shuffleQuestions,
    required this.shuffleAlternatives,
  });

  /// Valor salvo no Firestore (campo `applicationMode`).
  final String id;
  final String label;
  final String description;

  /// Gera uma prova exclusiva (com QR Code próprio) para cada aluno.
  final bool perStudent;
  final bool shuffleQuestions;
  final bool shuffleAlternatives;

  /// Valor legado (`sameExamForEveryone`), mantido para compatibilidade.
  bool get sameExamForEveryone => !perStudent;

  /// Quantidade de variantes quando não há alunos para individualizar.
  int get fallbackVariantCount => perStudent ? 4 : 1;

  /// Lê o modo salvo. Provas antigas só têm `sameExamForEveryone`.
  static ExamApplicationMode fromStored(Object? id, {bool? legacySameForEveryone}) {
    for (final mode in values) {
      if (mode.id == id) return mode;
    }
    if (legacySameForEveryone == false) return individual;
    return sameForEveryone;
  }
}
