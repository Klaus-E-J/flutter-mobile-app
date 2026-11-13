/// Payload estruturado contido no QR Code da folha de respostas OMR.
/// Formato: `AVALIA:1.0|{examId}|{variantId}|{studentId}`
class ExamQrPayload {
  const ExamQrPayload({
    required this.examId,
    required this.variantId,
    this.studentId,
  });

  final String examId;
  final String variantId;
  final String? studentId;

  String encode() {
    return 'AVALIA:1.0|$examId|$variantId|${studentId ?? ''}';
  }

  static ExamQrPayload? tryParse(String raw) {
    final trimmed = raw.trim();
    if (!trimmed.startsWith('AVALIA:1.0|')) return null;
    final parts = trimmed.split('|');
    if (parts.length < 3) return null;
    final examId = parts[1].trim();
    final variantId = parts[2].trim();
    if (examId.isEmpty || variantId.isEmpty) return null;
    final studentId = parts.length > 3 && parts[3].trim().isNotEmpty
        ? parts[3].trim()
        : null;
    return ExamQrPayload(
      examId: examId,
      variantId: variantId,
      studentId: studentId,
    );
  }
}

/// Representa uma alternativa permutada dentro de uma variante de prova.
class VariantAlternative {
  const VariantAlternative({
    required this.letter,
    required this.originalAlternativeId,
    required this.text,
    required this.isCorrect,
    this.originalLetter,
  });

  final String letter;
  final String originalAlternativeId;
  final String text;
  final bool isCorrect;

  /// Letra canônica original na questão mestre antes do embaralhamento ('A'..'E').
  final String? originalLetter;

  String get effectiveOriginalLetter =>
      (originalLetter != null && originalLetter!.isNotEmpty)
          ? originalLetter!
          : letter;

  factory VariantAlternative.fromMap(Map<String, dynamic> map) {
    final letter = map['letter'] as String? ?? 'A';
    return VariantAlternative(
      letter: letter,
      originalAlternativeId: map['originalAlternativeId'] as String? ?? '',
      text: map['text'] as String? ?? '',
      isCorrect: map['isCorrect'] as bool? ?? false,
      originalLetter: map['originalLetter'] as String? ?? letter,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'letter': letter,
      'originalAlternativeId': originalAlternativeId,
      'text': text,
      'isCorrect': isCorrect,
      'originalLetter': effectiveOriginalLetter,
    };
  }
}

/// Representa o mapeamento de uma questão em uma variante de prova (N3-02).
class VariantQuestionMapping {
  const VariantQuestionMapping({
    required this.questionNumber,
    required this.originalQuestionId,
    required this.originalQuestionOrder,
    required this.statement,
    required this.alternatives,
    required this.correctLetter,
    this.annulled = false,
    this.weight = 1.0,
  });

  final int questionNumber;
  final String originalQuestionId;
  final int originalQuestionOrder;
  final String statement;
  final List<VariantAlternative> alternatives;
  final String correctLetter;
  final bool annulled;
  final double weight;

  /// Número da questão na ordem canônica original (1..N).
  int get originalQuestionNumber => originalQuestionOrder + 1;

  /// Letra correta na ordem canônica original ('A'..'E').
  String get canonicalCorrectLetter {
    for (final alt in alternatives) {
      if (alt.letter.toUpperCase() == correctLetter.toUpperCase() ||
          alt.isCorrect) {
        return alt.effectiveOriginalLetter;
      }
    }
    return correctLetter;
  }

  /// Converte uma letra marcada na variante para a letra correspondente na questão canônica original.
  String toCanonicalLetter(String markedLetter) {
    final normalized = markedLetter.trim().toUpperCase();
    for (final alt in alternatives) {
      if (alt.letter.toUpperCase() == normalized) {
        return alt.effectiveOriginalLetter;
      }
    }
    return normalized;
  }

  factory VariantQuestionMapping.fromMap(Map<String, dynamic> map) {
    final rawAlts = map['alternatives'] as List<dynamic>? ?? const [];
    return VariantQuestionMapping(
      questionNumber: (map['questionNumber'] as num?)?.toInt() ?? 1,
      originalQuestionId: map['originalQuestionId'] as String? ?? '',
      originalQuestionOrder: (map['originalQuestionOrder'] as num?)?.toInt() ?? 0,
      statement: map['statement'] as String? ?? '',
      alternatives: rawAlts
          .whereType<Map<String, dynamic>>()
          .map(VariantAlternative.fromMap)
          .toList(),
      correctLetter: map['correctLetter'] as String? ?? 'A',
      annulled: map['annulled'] as bool? ?? false,
      weight: (map['weight'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'questionNumber': questionNumber,
      'originalQuestionId': originalQuestionId,
      'originalQuestionOrder': originalQuestionOrder,
      'statement': statement,
      'alternatives': alternatives.map((a) => a.toMap()).toList(),
      'correctLetter': correctLetter,
      'annulled': annulled,
      'weight': weight,
    };
  }
}

/// Representa uma variante gerada de uma prova com ordem de questões e
/// alternativas potencialmente embaralhadas e seu gabarito correspondente (N3-02).
class ExamVariant {
  const ExamVariant({
    required this.id,
    required this.examId,
    required this.code,
    required this.label,
    required this.questions,
    required this.answerKey,
    this.studentId,
    this.studentName,
    this.studentMatricula,
    this.classId,
    this.className,
  });

  final String id;
  final String examId;
  final String code;
  final String label;
  final List<VariantQuestionMapping> questions;

  /// Gabarito oficial da variante: número da questão (1..N) -> letra correta ('A'..'E').
  final Map<int, String> answerKey;

  final String? studentId;
  final String? studentName;
  final String? studentMatricula;
  final String? classId;
  final String? className;

  String get qrPayload => ExamQrPayload(
        examId: examId,
        variantId: id,
        studentId: studentId,
      ).encode();

  ExamVariant copyWith({
    String? id,
    String? examId,
    String? code,
    String? label,
    List<VariantQuestionMapping>? questions,
    Map<int, String>? answerKey,
    String? studentId,
    String? studentName,
    String? studentMatricula,
    String? classId,
    String? className,
  }) {
    return ExamVariant(
      id: id ?? this.id,
      examId: examId ?? this.examId,
      code: code ?? this.code,
      label: label ?? this.label,
      questions: questions ?? this.questions,
      answerKey: answerKey ?? this.answerKey,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentMatricula: studentMatricula ?? this.studentMatricula,
      classId: classId ?? this.classId,
      className: className ?? this.className,
    );
  }

  factory ExamVariant.fromMap(String id, Map<String, dynamic> map) {
    final rawQuestions = map['questions'] as List<dynamic>? ?? const [];
    final rawAnswerKey = map['answerKey'] as Map<String, dynamic>? ?? const {};

    final questions = rawQuestions
        .whereType<Map<String, dynamic>>()
        .map(VariantQuestionMapping.fromMap)
        .toList();

    final answerKey = <int, String>{};
    rawAnswerKey.forEach((key, value) {
      final qNum = int.tryParse(key);
      if (qNum != null && value is String) {
        answerKey[qNum] = value;
      }
    });

    if (answerKey.isEmpty) {
      for (final q in questions) {
        answerKey[q.questionNumber] = q.correctLetter;
      }
    }

    return ExamVariant(
      id: id,
      examId: map['examId'] as String? ?? '',
      code: map['code'] as String? ?? 'A',
      label: map['label'] as String? ?? 'Caderno A',
      questions: questions,
      answerKey: answerKey,
      studentId: map['studentId'] as String?,
      studentName: map['studentName'] as String?,
      studentMatricula: map['studentMatricula'] as String?,
      classId: map['classId'] as String?,
      className: map['className'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'examId': examId,
      'code': code,
      'label': label,
      'questions': questions.map((q) => q.toMap()).toList(),
      'answerKey': {
        for (final entry in answerKey.entries) entry.key.toString(): entry.value,
      },
      if (studentId != null) 'studentId': studentId,
      if (studentName != null) 'studentName': studentName,
      if (studentMatricula != null) 'studentMatricula': studentMatricula,
      if (classId != null) 'classId': classId,
      if (className != null) 'className': className,
    };
  }
}
