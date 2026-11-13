import 'dart:math';

import '../../../screens/provas/models/questao_model.dart';
import '../../classes/data/class_repository.dart';
import '../models/exam_variant.dart';

/// Serviço responsável pela randomização de questões e alternativas de provas,
/// garantindo correspondência exata entre variantes e gabaritos (N3-02).
class ExamRandomizerService {
  const ExamRandomizerService();

  static const List<String> _letters = ['A', 'B', 'C', 'D', 'E'];
  static const List<String> _variantCodes = ['A', 'B', 'C', 'D', 'E'];

  /// Gera as variantes da prova de acordo com o modo configurado:
  /// - [sameExamForEveryone] = true: gera [variantCount] cadernos (A, B, C, D)
  ///   com questões e alternativas embaralhadas.
  /// - [sameExamForEveryone] = false: gera 1 variante exclusiva para cada aluno
  ///   em [students] (ou [variantCount] variantes caso [students] esteja vazio).
  List<ExamVariant> generateVariants({
    required String examId,
    required List<Questao> questions,
    required bool sameExamForEveryone,
    List<StudentRecord> students = const [],
    String? classId,
    String? className,
    int variantCount = 4,
    bool shuffleQuestions = true,
    bool shuffleAlternatives = true,
    int? seed,
  }) {
    if (questions.isEmpty) return const [];

    final baseSeed = seed ?? examId.hashCode;

    if (!sameExamForEveryone && students.isNotEmpty) {
      final variants = <ExamVariant>[];
      for (var i = 0; i < students.length; i++) {
        final student = students[i];
        final studentRandom = Random(baseSeed ^ student.id.hashCode ^ (i * 7919));
        final code = 'IND-${(i + 1).toString().padLeft(2, '0')}';
        final safeStudentId = student.id.isNotEmpty ? student.id : 'std_${i + 1}';

        variants.add(
          _buildSingleVariant(
            id: 'var_$safeStudentId',
            examId: examId,
            code: code,
            label: 'Prova Individual - ${student.name}',
            masterQuestions: questions,
            random: studentRandom,
            shuffleQuestions: shuffleQuestions,
            shuffleAlternatives: shuffleAlternatives,
            studentId: student.id.isNotEmpty ? student.id : null,
            studentName: student.name,
            studentMatricula: student.matricula.isNotEmpty ? student.matricula : null,
            classId: classId,
            className: className,
          ),
        );
      }
      return variants;
    }

    final count = variantCount.clamp(1, _variantCodes.length);
    final variants = <ExamVariant>[];
    for (var i = 0; i < count; i++) {
      final code = _variantCodes[i];
      final variantRandom = Random(baseSeed ^ (i * 104729));
      variants.add(
        _buildSingleVariant(
          id: 'variant_$code',
          examId: examId,
          code: code,
          label: 'Caderno $code',
          masterQuestions: questions,
          random: variantRandom,
          shuffleQuestions: shuffleQuestions,
          shuffleAlternatives: shuffleAlternatives,
          classId: classId,
          className: className,
        ),
      );
    }
    return variants;
  }

  /// Gera folhas de resposta OMR identificadas individualmente por aluno (nome, matrícula
  /// e QR Code nominal `AVALIA:1.0|examId|variantId|studentId`) mesmo quando a prova
  /// é comum para a turma (`sameExamForEveryone == true`) (requisito cliente §6).
  List<ExamVariant> buildNominalAnswerSheetVariants({
    required List<ExamVariant> baseVariants,
    required List<StudentRecord> students,
    String? classId,
    String? className,
  }) {
    if (baseVariants.isEmpty) return const [];
    if (students.isEmpty) return baseVariants;

    // Se as variantes já estão identificadas por aluno (modo individual), retorna como estão.
    if (baseVariants.every((v) => v.studentId != null && v.studentId!.isNotEmpty)) {
      return baseVariants;
    }

    final nominalSheets = <ExamVariant>[];
    for (var i = 0; i < students.length; i++) {
      final student = students[i];
      final assignedVariant = baseVariants[i % baseVariants.length];
      final safeStudentId = student.id.isNotEmpty ? student.id : 'std_${i + 1}';

      nominalSheets.add(
        assignedVariant.copyWith(
          studentId: safeStudentId,
          studentName: student.name,
          studentMatricula: student.matricula.isNotEmpty ? student.matricula : null,
          classId: classId ?? assignedVariant.classId,
          className: className ?? assignedVariant.className,
        ),
      );
    }
    return nominalSheets;
  }

  /// Constrói uma variante canônica (sem embaralhamento) a partir das questões originais.
  ExamVariant buildCanonicalVariant({
    required String examId,
    required List<Questao> questions,
    String code = 'A',
    String label = 'Caderno A',
  }) {
    return _buildSingleVariant(
      id: 'variant_$code',
      examId: examId,
      code: code,
      label: label,
      masterQuestions: questions,
      random: Random(0),
      shuffleQuestions: false,
      shuffleAlternatives: false,
    );
  }

  ExamVariant _buildSingleVariant({
    required String id,
    required String examId,
    required String code,
    required String label,
    required List<Questao> masterQuestions,
    required Random random,
    required bool shuffleQuestions,
    required bool shuffleAlternatives,
    String? studentId,
    String? studentName,
    String? studentMatricula,
    String? classId,
    String? className,
  }) {
    final indexedQuestions = List<({int originalOrder, Questao question})>.generate(
      masterQuestions.length,
      (index) => (originalOrder: index, question: masterQuestions[index]),
    );

    if (shuffleQuestions && indexedQuestions.length > 1) {
      indexedQuestions.shuffle(random);
    }

    final mappedQuestions = <VariantQuestionMapping>[];
    final answerKey = <int, String>{};

    for (var qIdx = 0; qIdx < indexedQuestions.length; qIdx++) {
      final questionNumber = qIdx + 1;
      final entry = indexedQuestions[qIdx];
      final masterQ = entry.question;

      final indexedAlternatives = List<({String originalLetter, Alternativa alt})>.generate(
        masterQ.alternativas.length,
        (idx) => (
          originalLetter: idx < _letters.length ? _letters[idx] : 'E',
          alt: masterQ.alternativas[idx],
        ),
      );
      if (shuffleAlternatives && indexedAlternatives.length > 1) {
        indexedAlternatives.shuffle(random);
      }

      final variantAlternatives = <VariantAlternative>[];
      String? detectedCorrectLetter;

      for (var aIdx = 0; aIdx < indexedAlternatives.length; aIdx++) {
        final letter = aIdx < _letters.length ? _letters[aIdx] : 'E';
        final altEntry = indexedAlternatives[aIdx];
        final alt = altEntry.alt;
        if (alt.correta) {
          detectedCorrectLetter = letter;
        }
        variantAlternatives.add(
          VariantAlternative(
            letter: letter,
            originalAlternativeId: alt.id,
            text: alt.texto,
            isCorrect: alt.correta,
            originalLetter: altEntry.originalLetter,
          ),
        );
      }

      final correctLetter = detectedCorrectLetter ??
          (variantAlternatives.isNotEmpty ? variantAlternatives.first.letter : 'A');

      mappedQuestions.add(
        VariantQuestionMapping(
          questionNumber: questionNumber,
          originalQuestionId: masterQ.id,
          originalQuestionOrder: entry.originalOrder,
          statement: masterQ.enunciado,
          alternatives: variantAlternatives,
          correctLetter: correctLetter,
        ),
      );
      answerKey[questionNumber] = correctLetter;
    }

    return ExamVariant(
      id: id,
      examId: examId,
      code: code,
      label: label,
      questions: mappedQuestions,
      answerKey: answerKey,
      studentId: studentId,
      studentName: studentName,
      studentMatricula: studentMatricula,
      classId: classId,
      className: className,
    );
  }

  /// Verifica matematicamente se uma [variant] preserva todas as questões de
  /// [masterQuestions] e se cada letra em [variant.answerKey] aponta exatamente
  /// para a alternativa marcada como correta na questão original.
  bool verifyVariantIntegrity(
    ExamVariant variant,
    List<Questao> masterQuestions,
  ) {
    if (variant.questions.length != masterQuestions.length) return false;
    if (variant.answerKey.length != masterQuestions.length) return false;

    final masterById = {for (final q in masterQuestions) q.id: q};
    final seenOriginalIds = <String>{};

    for (final vq in variant.questions) {
      final master = masterById[vq.originalQuestionId];
      if (master == null) return false;
      if (!seenOriginalIds.add(vq.originalQuestionId)) return false;

      final keyLetter = variant.answerKey[vq.questionNumber];
      if (keyLetter == null || keyLetter != vq.correctLetter) return false;

      final masterCorrect = master.alternativaCorreta;
      if (masterCorrect == null) continue;

      final matchingAlt = vq.alternatives.where((a) => a.letter == keyLetter).toList();
      if (matchingAlt.length != 1) return false;

      final chosen = matchingAlt.single;
      if (!chosen.isCorrect) return false;
      if (chosen.originalAlternativeId != masterCorrect.id) return false;
      if (chosen.text != masterCorrect.texto) return false;
    }

    return true;
  }
}
