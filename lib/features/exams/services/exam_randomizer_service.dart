import 'dart:math';

import '../../../screens/provas/models/questao_model.dart';
import '../../classes/data/class_repository.dart';
import '../models/exam_application_mode.dart';
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

    final baseSeed = seed ?? defaultSeedFor(examId);

    if (!sameExamForEveryone && students.isNotEmpty) {
      final variants = <ExamVariant>[];
      for (var i = 0; i < students.length; i++) {
        final student = students[i];
        final safeStudentId = student.id.isNotEmpty ? student.id : 'std_${i + 1}';
        // A semente depende só da prova e do ID do aluno — nunca da posição
        // dele na lista. Incluir/remover alunos não altera as provas dos demais.
        final studentRandom = Random(baseSeed ^ stableHash(safeStudentId));
        final code = 'IND-${(i + 1).toString().padLeft(2, '0')}';

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
            classId: student.classId ?? classId,
            className: student.className ?? className,
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

  /// Gera as variantes seguindo o [mode] de aplicação da prova:
  /// - modos "por aluno": uma variante por aluno, embaralhando só o que o
  ///   modo define (questões, alternativas ou ambos);
  /// - "mesma prova": uma única variante na ordem original.
  List<ExamVariant> generateVariantsForMode({
    required String examId,
    required List<Questao> questions,
    required ExamApplicationMode mode,
    List<StudentRecord> students = const [],
    String? classId,
    String? className,
    int? seed,
  }) {
    return generateVariants(
      examId: examId,
      questions: questions,
      sameExamForEveryone: mode.sameExamForEveryone,
      students: students,
      classId: classId,
      className: className,
      variantCount: mode.fallbackVariantCount,
      shuffleQuestions: mode.shuffleQuestions,
      shuffleAlternatives: mode.shuffleAlternatives,
      seed: seed,
    );
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
          classId: student.classId ?? classId ?? assignedVariant.classId,
          className: student.className ?? className ?? assignedVariant.className,
        ),
      );
    }
    return nominalSheets;
  }

  /// Hash FNV-1a de 32 bits: estável entre execuções, versões do Dart e
  /// plataformas (ao contrário de `String.hashCode`).
  ///
  /// Na Web (JavaScript) os inteiros são `double` com 53 bits de precisão:
  /// `hash * 0x01000193` passaria de 2^53 e daria outro resultado que no
  /// celular. Por isso o produto é decomposto em partes que cabem em 53 bits
  /// (0x01000193 = 2^24 + 0x193), dando o mesmo valor em todas as plataformas.
  static int stableHash(String value) {
    var hash = 0x811c9dc5;
    for (final unit in value.codeUnits) {
      hash = (hash ^ unit) & 0xFFFFFFFF;
      hash = (hash * 0x193 + ((hash << 24) & 0xFFFFFFFF)) & 0xFFFFFFFF;
    }
    return hash;
  }

  /// Semente padrão da prova, usada enquanto o professor não pede um
  /// "Reembaralhar". Depende apenas do ID da prova.
  static int defaultSeedFor(String examId) => stableHash('seed|$examId');

  /// Impressão digital da configuração que define o conteúdo das variantes:
  /// modo de aplicação, semente e conteúdo das questões (enunciados,
  /// alternativas e alternativa correta). Renomear a prova, trocar turmas ou
  /// incluir alunos não altera este valor.
  static String configFingerprint({
    required ExamApplicationMode mode,
    required int seed,
    required List<Questao> questions,
  }) {
    final buffer = StringBuffer('${mode.id}|$seed');
    for (final q in questions) {
      buffer.write('|Q:${q.id}:${q.enunciado.trim()}');
      for (final a in q.alternativas) {
        buffer.write('|A:${a.id}:${a.texto.trim()}:${a.correta ? 1 : 0}');
      }
    }
    final text = buffer.toString();
    // Dois hashes independentes reduzem a chance de colisão.
    final h1 = stableHash(text).toRadixString(16).padLeft(8, '0');
    final h2 = stableHash('x|$text|${text.length}').toRadixString(16).padLeft(8, '0');
    return '$h1$h2';
  }

  /// Combina as variantes recém-geradas com as que já estão salvas.
  ///
  /// Regras (para nunca invalidar folhas já impressas sem necessidade):
  /// - Variante salva com a mesma [fingerprint] e o mesmo ID é mantida
  ///   intacta (questões, gabarito e código); só os dados do aluno/turma são
  ///   atualizados (ex.: nome corrigido).
  /// - Variantes por aluno salvas com a mesma [fingerprint] cujo aluno não
  ///   está mais na lista são preservadas, para que folhas já impressas
  ///   continuem sendo reconhecidas.
  /// - Variantes antigas (sem fingerprint, criadas por versões anteriores do
  ///   app) são reaproveitadas quando ainda conferem com as questões atuais
  ///   ([legacyQuestions]).
  /// - Novas variantes recebem um código que não colide com os existentes.
  List<ExamVariant> mergeWithExisting({
    required List<ExamVariant> generated,
    required List<ExamVariant> existing,
    required String fingerprint,
    List<Questao>? legacyQuestions,
  }) {
    final perStudent =
        generated.isNotEmpty && (generated.first.studentId ?? '').isNotEmpty;

    bool reusable(ExamVariant e) {
      if (e.configFingerprint == fingerprint) return true;
      if (e.configFingerprint == null && legacyQuestions != null) {
        final isPerStudent = (e.studentId ?? '').isNotEmpty;
        return isPerStudent == perStudent &&
            _matchesQuestions(e, legacyQuestions);
      }
      return false;
    }

    final reusableById = {
      for (final e in existing)
        if (reusable(e)) e.id: e,
    };
    final generatedIds = generated.map((g) => g.id).toSet();
    // Variantes por aluno salvas cujo aluno não está mais na lista: são
    // preservadas (folha já impressa continua reconhecível).
    final preserved = perStudent
        ? reusableById.values
            .where((e) => !generatedIds.contains(e.id) && (e.studentId ?? '').isNotEmpty)
            .toList()
        : const <ExamVariant>[];
    final usedCodes = <String>{
      for (final g in generated)
        if (reusableById.containsKey(g.id)) reusableById[g.id]!.code,
      for (final e in preserved) e.code,
    };

    var nextIndividual = 1;
    String freeIndividualCode() {
      while (true) {
        final code = 'IND-${nextIndividual.toString().padLeft(2, '0')}';
        nextIndividual++;
        if (!usedCodes.contains(code)) return code;
      }
    }

    final result = <ExamVariant>[];
    for (final g in generated) {
      final kept = reusableById[g.id];
      if (kept != null) {
        result.add(
          kept.copyWith(
            label: g.label,
            studentName: g.studentName,
            studentMatricula: g.studentMatricula,
            classId: g.classId,
            className: g.className,
            configFingerprint: fingerprint,
          ),
        );
        continue;
      }
      var code = g.code;
      if (g.studentId != null && usedCodes.contains(code)) {
        code = freeIndividualCode();
      }
      usedCodes.add(code);
      result.add(g.copyWith(code: code, configFingerprint: fingerprint));
    }

    for (final e in preserved) {
      result.add(e.copyWith(configFingerprint: fingerprint));
    }

    result.sort((a, b) => a.code.compareTo(b.code));
    return result;
  }

  /// A variante antiga ainda confere com as [questions] atuais (mesmas
  /// questões e alternativas e gabarito apontando para a alternativa correta
  /// atual)? Os textos são comparados sem espaços nas pontas, pois versões
  /// anteriores salvavam o texto digitado no editor e o Firestore guarda o
  /// texto aparado.
  bool _matchesQuestions(ExamVariant variant, List<Questao> questions) {
    if (variant.questions.length != questions.length) return false;
    if (variant.answerKey.length != questions.length) return false;
    final byId = {for (final q in questions) q.id: q};
    final seenQuestions = <String>{};
    for (final vq in variant.questions) {
      final master = byId[vq.originalQuestionId];
      if (master == null || !seenQuestions.add(vq.originalQuestionId)) {
        return false;
      }
      if (master.enunciado.trim() != vq.statement.trim()) return false;
      if (master.alternativas.length != vq.alternatives.length) return false;
      final masterAlts = {for (final a in master.alternativas) a.id: a};
      final seenAlts = <String>{};
      for (final va in vq.alternatives) {
        final ma = masterAlts[va.originalAlternativeId];
        if (ma == null ||
            !seenAlts.add(va.originalAlternativeId) ||
            ma.texto.trim() != va.text.trim() ||
            ma.correta != va.isCorrect) {
          return false;
        }
      }

      final keyLetter = variant.answerKey[vq.questionNumber];
      if (keyLetter == null || keyLetter != vq.correctLetter) return false;
      final masterCorrect = master.alternativaCorreta;
      if (masterCorrect == null) continue;
      final chosen = vq.alternatives.where((a) => a.letter == keyLetter).toList();
      if (chosen.length != 1 ||
          chosen.single.originalAlternativeId != masterCorrect.id) {
        return false;
      }
    }
    return true;
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
