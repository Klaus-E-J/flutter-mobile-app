import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/firebase_service.dart';

/// Resposta individual de uma questão em uma submissão.
class SubmissionQuestionAnswer {
  const SubmissionQuestionAnswer({
    required this.questionNumber,
    required this.marked,
    required this.correct,
    required this.isCorrect,
  });

  final int questionNumber;
  final String marked;
  final String correct;
  final bool isCorrect;

  factory SubmissionQuestionAnswer.fromMap(Map<String, dynamic> map) {
    return SubmissionQuestionAnswer(
      questionNumber: (map['questionNumber'] as num?)?.toInt() ?? 0,
      marked: map['marked'] as String? ?? '',
      correct: map['correct'] as String? ?? '',
      isCorrect: map['isCorrect'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'questionNumber': questionNumber,
      'marked': marked,
      'correct': correct,
      'isCorrect': isCorrect,
    };
  }
}

/// Registro persistido de uma submissão/correção de prova de um aluno.
class SubmissionRecord {
  const SubmissionRecord({
    required this.id,
    required this.examId,
    required this.examTitle,
    required this.classId,
    required this.className,
    required this.studentId,
    required this.studentName,
    required this.score,
    required this.totalQuestions,
    required this.percentage,
    required this.answers,
    this.createdAt,
  });

  final String id;
  final String examId;
  final String examTitle;
  final String classId;
  final String className;
  final String studentId;
  final String studentName;
  final int score;
  final int totalQuestions;
  final double percentage;
  final List<SubmissionQuestionAnswer> answers;
  final DateTime? createdAt;

  String get nota => '$score/$totalQuestions';

  factory SubmissionRecord.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final rawAnswers = data['answers'] as List<dynamic>? ?? const [];
    final timestamp = data['createdAt'] as Timestamp?;

    return SubmissionRecord(
      id: document.id,
      examId: data['examId'] as String? ?? '',
      examTitle: data['examTitle'] as String? ?? '',
      classId: data['classId'] as String? ?? '',
      className: data['className'] as String? ?? '',
      studentId: data['studentId'] as String? ?? '',
      studentName: data['studentName'] as String? ?? '',
      score: (data['score'] as num?)?.toInt() ?? 0,
      totalQuestions: (data['totalQuestions'] as num?)?.toInt() ?? 0,
      percentage: (data['percentage'] as num?)?.toDouble() ?? 0.0,
      answers: rawAnswers
          .whereType<Map<String, dynamic>>()
          .map(SubmissionQuestionAnswer.fromMap)
          .toList(),
      createdAt: timestamp?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'examId': examId,
      'examTitle': examTitle,
      'classId': classId,
      'className': className,
      'studentId': studentId,
      'studentName': studentName,
      'score': score,
      'totalQuestions': totalQuestions,
      'percentage': percentage,
      'answers': answers.map((a) => a.toMap()).toList(),
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}

/// Resumo agrupado das correções de uma prova.
class ExamCorrectionSummary {
  const ExamCorrectionSummary({
    required this.examId,
    required this.examTitle,
    required this.classId,
    required this.className,
    required this.submissions,
    required this.totalQuestions,
    this.lastCorrectionDate,
  });

  final String examId;
  final String examTitle;
  final String classId;
  final String className;
  final List<SubmissionRecord> submissions;
  final int totalQuestions;
  final DateTime? lastCorrectionDate;

  int get studentCount => submissions.length;

  double get averageScore {
    if (submissions.isEmpty) return 0.0;
    final total = submissions.fold<double>(
      0.0,
      (acc, s) => acc + s.percentage,
    );
    return total / submissions.length;
  }
}

/// Repositório para gerenciar submissões de correção no Cloud Firestore.
/// Localizado em: `users/{uid}/submissions/{submissionId}`
class SubmissionRepository {
  CollectionReference<Map<String, dynamic>> get _submissions =>
      FirebaseService.userCollection('submissions');

  /// Salva uma lista de submissões em lote (batch).
  Future<void> saveSubmissions(List<SubmissionRecord> records) async {
    if (records.isEmpty) return;

    final batch = FirebaseService.firestore.batch();
    for (final record in records) {
      final docRef = record.id.isEmpty
          ? _submissions.doc()
          : _submissions.doc(record.id);

      final data = record.toMap();
      data['createdAt'] = FieldValue.serverTimestamp();
      batch.set(docRef, data);
    }

    await batch.commit();
  }

  /// Observa todas as submissões em tempo real.
  Stream<List<SubmissionRecord>> watchSubmissions() {
    return _submissions
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(SubmissionRecord.fromDocument).toList());
  }

  /// Recupera todas as submissões uma vez.
  Future<List<SubmissionRecord>> getSubmissions() async {
    final snapshot = await _submissions
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map(SubmissionRecord.fromDocument).toList();
  }

  /// Recupera submissões filtradas por prova.
  Future<List<SubmissionRecord>> getSubmissionsByExam(String examId) async {
    final snapshot = await _submissions
        .where('examId', isEqualTo: examId)
        .get();
    return snapshot.docs.map(SubmissionRecord.fromDocument).toList();
  }

  /// Observa os resumos de provas corrigidas agrupados por prova/turma.
  Stream<List<ExamCorrectionSummary>> watchExamSummaries() {
    return watchSubmissions().map(_groupSubmissionsByExam);
  }

  /// Agrupa uma lista de submissões por prova e turma.
  static List<ExamCorrectionSummary> _groupSubmissionsByExam(
    List<SubmissionRecord> submissions,
  ) {
    final groups = <String, List<SubmissionRecord>>{};
    for (final sub in submissions) {
      final key = '${sub.examId}|${sub.classId}';
      groups.putIfAbsent(key, () => []).add(sub);
    }

    final summaries = <ExamCorrectionSummary>[];
    for (final entry in groups.entries) {
      final subs = entry.value;
      if (subs.isEmpty) continue;
      final first = subs.first;
      subs.sort((a, b) => a.studentName.compareTo(b.studentName));

      summaries.add(
        ExamCorrectionSummary(
          examId: first.examId,
          examTitle: first.examTitle,
          classId: first.classId,
          className: first.className,
          submissions: subs,
          totalQuestions: first.totalQuestions,
          lastCorrectionDate: subs.map((s) => s.createdAt).whereType<DateTime>().isNotEmpty
              ? subs.map((s) => s.createdAt).whereType<DateTime>().reduce((a, b) => a.isAfter(b) ? a : b)
              : null,
        ),
      );
    }

    return summaries;
  }
}
