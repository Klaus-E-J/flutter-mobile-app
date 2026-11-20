import '../../../features/correction/data/submission_repository.dart';
import '../../../features/exams/models/exam_application_mode.dart';

/// Representa uma prova disponível para correção.
class ProvaCorrecao {
  const ProvaCorrecao({
    required this.id,
    required this.titulo,
    required this.turma,
    required this.disciplina,
    required this.totalQuestoes,
    required this.totalAlunos,
    bool provaIndividual = false,
    ExamApplicationMode? modoAplicacao,
    this.dataCriacao,
    this.classId,
  }) : modoAplicacao = modoAplicacao ??
            (provaIndividual
                ? ExamApplicationMode.individual
                : ExamApplicationMode.sameForEveryone);

  final String id;
  final String titulo;
  final String turma;
  final String disciplina;
  final int totalQuestoes;
  final int totalAlunos;

  /// Como a prova foi aplicada (o que muda de um aluno para outro).
  final ExamApplicationMode modoAplicacao;

  /// `true` quando cada aluno tem uma prova própria (com QR Code individual).
  bool get provaIndividual => modoAplicacao.perStudent;

  final DateTime? dataCriacao;
  final String? classId;
}

/// Resultado de uma prova escaneada e corrigida de um aluno (N3-04 / N3-05).
class ResultadoAluno {
  const ResultadoAluno({
    required this.nomeAluno,
    required this.acertos,
    required this.totalQuestoes,
    this.erro = false,
    this.submissionId,
    this.studentId,
    this.variantId = '',
    this.variantCode = 'A',
    this.emBranco = 0,
    this.invalidas = 0,
    this.notaFinal10,
    this.answers,
  });

  final String nomeAluno;
  final int acertos;
  final int totalQuestoes;
  final bool erro;
  final String? submissionId;
  final String? studentId;
  final String variantId;
  final String variantCode;
  final int emBranco;
  final int invalidas;
  final double? notaFinal10;
  final List<SubmissionQuestionAnswer>? answers;

  double get percentual =>
      totalQuestoes > 0 ? (acertos / totalQuestoes) * 100 : 0;

  double get nota10 =>
      notaFinal10 ?? (totalQuestoes > 0 ? (acertos / totalQuestoes) * 10.0 : 0.0);

  String get nota => '$acertos/$totalQuestoes';
}

/// Estados do leitor de câmera/imagem OMR.
enum LeituraStatus { aguardando, processando, sucesso, erro }
