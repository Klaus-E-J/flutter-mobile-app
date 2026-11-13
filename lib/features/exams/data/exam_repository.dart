import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/firebase_service.dart';
import '../../../screens/provas/models/questao_model.dart';
import '../../classes/data/class_repository.dart';
import '../models/exam_variant.dart';
import '../services/exam_randomizer_service.dart';

class ExamRecord {
  const ExamRecord({
    required this.id,
    required this.title,
    required this.classIds,
    required this.classNames,
    required this.sameExamForEveryone,
    required this.questionCount,
  });

  final String id;
  final String title;
  final List<String> classIds;
  final List<String> classNames;
  final bool sameExamForEveryone;
  final int questionCount;

  factory ExamRecord.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    return ExamRecord(
      id: document.id,
      title: data['title'] as String? ?? '',
      classIds: (data['classIds'] as List<dynamic>? ?? const []).whereType<String>().toList(),
      classNames: (data['classNames'] as List<dynamic>? ?? const []).whereType<String>().toList(),
      sameExamForEveryone: data['sameExamForEveryone'] as bool? ?? true,
      questionCount: (data['questionCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class ExamRepository {
  CollectionReference<Map<String, dynamic>> get _exams =>
      FirebaseService.userCollection('exams');

  Stream<List<ExamRecord>> watchExams() => _exams
      .orderBy('title')
      .snapshots()
      .map((snapshot) => snapshot.docs.map(ExamRecord.fromDocument).toList());

  Future<List<ExamRecord>> getExams() async {
    final snapshot = await _exams.orderBy('title').get();
    return snapshot.docs.map(ExamRecord.fromDocument).toList();
  }

  Future<ExamRecord?> getExam(String examId) async {
    final doc = await _exams.doc(examId).get();
    if (!doc.exists) return null;
    return ExamRecord.fromDocument(doc);
  }

  Future<String> saveExam({
    String? id,
    required String title,
    required List<String> classIds,
    required List<String> classNames,
    required bool sameExamForEveryone,
  }) async {
    final trimmedTitle = title.trim();
    final reference = id == null ? _exams.doc() : _exams.doc(id);
    final data = <String, dynamic>{
      'title': trimmedTitle,
      'classId': classIds.isNotEmpty ? classIds.first : '',
      'className': classNames.isNotEmpty ? classNames.first : '',
      'classIds': classIds,
      'classNames': classNames,
      'sameExamForEveryone': sameExamForEveryone,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (id == null) {
      data['createdAt'] = FieldValue.serverTimestamp();
      data['questionCount'] = 0;
    }
    await reference.set(data, SetOptions(merge: true));

    if (id != null) {
      try {
        final subCol = FirebaseService.userCollection('submissions');
        final subSnap = await subCol.where('examId', isEqualTo: id).get();
        const batchSize = 400;
        final subDocs = subSnap.docs;
        for (var i = 0; i < subDocs.length; i += batchSize) {
          final end = (i + batchSize < subDocs.length)
              ? i + batchSize
              : subDocs.length;
          final batch = FirebaseService.firestore.batch();
          for (final doc in subDocs.sublist(i, end)) {
            batch.update(doc.reference, {'examTitle': trimmedTitle});
          }
          await batch.commit();
        }
      } catch (_) {}
    }

    return reference.id;
  }

  /// Exclui a prova, suas subcoleções (`questions` e `variants`) e, opcionalmente, submissões vinculadas.
  Future<void> deleteExam(
    String examId, {
    bool deleteSubmissions = false,
  }) async {
    final examReference = _exams.doc(examId);
    final questionsSnap = await examReference.collection('questions').get();
    final variantsSnap = await examReference.collection('variants').get();

    final refsToDelete = <DocumentReference>[
      ...questionsSnap.docs.map((d) => d.reference),
      ...variantsSnap.docs.map((d) => d.reference),
    ];

    if (deleteSubmissions) {
      final subCol = FirebaseService.userCollection('submissions');
      final subSnap = await subCol.where('examId', isEqualTo: examId).get();
      refsToDelete.addAll(subSnap.docs.map((d) => d.reference));
    }

    const batchSize = 400;
    for (var i = 0; i < refsToDelete.length; i += batchSize) {
      final end = (i + batchSize < refsToDelete.length)
          ? i + batchSize
          : refsToDelete.length;
      final batch = FirebaseService.firestore.batch();
      for (final ref in refsToDelete.sublist(i, end)) {
        batch.delete(ref);
      }
      await batch.commit();
    }

    await examReference.delete();
  }

  Stream<List<Questao>> watchQuestions(String examId) => _exams
      .doc(examId)
      .collection('questions')
      .orderBy('order')
      .snapshots()
      .map((snapshot) => snapshot.docs.map(_questionFromDocument).toList());

  Future<List<Questao>> getQuestions(String examId) async {
    final snapshot = await _exams
        .doc(examId)
        .collection('questions')
        .orderBy('order')
        .get();
    return snapshot.docs.map(_questionFromDocument).toList();
  }

  Questao _questionFromDocument(QueryDocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data();
    final rawAlternatives = data['alternatives'] as List<dynamic>? ?? const [];
    return Questao(
      id: document.id,
      enunciado: data['statement'] as String? ?? '',
      alternativas: rawAlternatives.whereType<Map<String, dynamic>>().map((alternative) {
        return Alternativa(
          id: alternative['id'] as String? ?? '',
          texto: alternative['text'] as String? ?? '',
          correta: alternative['correct'] as bool? ?? false,
        );
      }).toList(),
    );
  }

  Future<void> saveQuestions(String examId, List<Questao> questions) async {
    final examReference = _exams.doc(examId);
    final questionsReference = examReference.collection('questions');
    final existing = await questionsReference.get();

    const batchSize = 400;
    final retainedIds = questions.map((question) => question.id).toSet();
    final toDelete =
        existing.docs.where((d) => !retainedIds.contains(d.id)).toList();

    for (var i = 0; i < toDelete.length; i += batchSize) {
      final end =
          (i + batchSize < toDelete.length) ? i + batchSize : toDelete.length;
      final batch = FirebaseService.firestore.batch();
      for (final doc in toDelete.sublist(i, end)) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }

    for (var i = 0; i < questions.length; i += batchSize) {
      final end = (i + batchSize < questions.length)
          ? i + batchSize
          : questions.length;
      final batch = FirebaseService.firestore.batch();
      for (var index = i; index < end; index++) {
        final question = questions[index];
        batch.set(questionsReference.doc(question.id), {
          'statement': question.enunciado.trim(),
          'order': index,
          'alternatives': question.alternativas
              .map((alternative) => {
                    'id': alternative.id,
                    'text': alternative.texto.trim(),
                    'correct': alternative.correta,
                  })
              .toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }

    await examReference.update({
      'questionCount': questions.length,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Sempre que as questões mudam, regenera as variantes e gabaritos da prova (N3-02).
    if (questions.isNotEmpty) {
      try {
        await regenerateVariantsForExam(examId: examId, questions: questions);
      } catch (_) {
        // Fallback silencioso se offline/sem turmas
      }
    }
  }

  /// Salva as variantes randomizadas da prova em `users/{uid}/exams/{examId}/variants/{variantId}`.
  Future<void> saveVariants(String examId, List<ExamVariant> variants) async {
    final variantsRef = _exams.doc(examId).collection('variants');
    final existing = await variantsRef.get();
    final retainedIds = variants.map((v) => v.id).toSet();

    const batchSize = 400;
    final toDelete = existing.docs.where((d) => !retainedIds.contains(d.id)).toList();

    for (var i = 0; i < toDelete.length; i += batchSize) {
      final end = (i + batchSize < toDelete.length) ? i + batchSize : toDelete.length;
      final batch = FirebaseService.firestore.batch();
      for (final doc in toDelete.sublist(i, end)) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }

    for (var i = 0; i < variants.length; i += batchSize) {
      final end = (i + batchSize < variants.length) ? i + batchSize : variants.length;
      final batch = FirebaseService.firestore.batch();
      for (final variant in variants.sublist(i, end)) {
        final data = variant.toMap();
        data['updatedAt'] = FieldValue.serverTimestamp();
        batch.set(variantsRef.doc(variant.id), data);
      }
      await batch.commit();
    }
  }

  /// Recupera todas as variantes salvas para uma prova.
  Future<List<ExamVariant>> getVariants(String examId) async {
    final snapshot = await _exams.doc(examId).collection('variants').get();
    final list = snapshot.docs
        .map((doc) => ExamVariant.fromMap(doc.id, doc.data()))
        .toList();
    list.sort((a, b) => a.code.compareTo(b.code));
    return list;
  }

  /// Observa as variantes de uma prova em tempo real.
  Stream<List<ExamVariant>> watchVariants(String examId) {
    return _exams.doc(examId).collection('variants').snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ExamVariant.fromMap(doc.id, doc.data()))
          .toList();
      list.sort((a, b) => a.code.compareTo(b.code));
      return list;
    });
  }

  /// Gera e salva as variantes da prova com base na configuração (Mesma prova ou Por aluno).
  Future<List<ExamVariant>> regenerateVariantsForExam({
    required String examId,
    List<Questao>? questions,
    int variantCount = 4,
  }) async {
    final exam = await getExam(examId);
    final examQuestions = questions ?? await getQuestions(examId);
    if (examQuestions.isEmpty) return const [];

    final sameForEveryone = exam?.sameExamForEveryone ?? true;
    final students = <StudentRecord>[];
    String? firstClassId;
    String? firstClassName;

    if (!sameForEveryone && exam != null && exam.classIds.isNotEmpty) {
      final classRepo = ClassRepository();
      firstClassId = exam.classIds.first;
      firstClassName = exam.classNames.isNotEmpty ? exam.classNames.first : null;
      for (final classId in exam.classIds) {
        final classStudents = await classRepo.getStudents(classId);
        students.addAll(classStudents);
      }
    }

    const randomizer = ExamRandomizerService();
    final variants = randomizer.generateVariants(
      examId: examId,
      questions: examQuestions,
      sameExamForEveryone: sameForEveryone,
      students: students,
      classId: firstClassId,
      className: firstClassName,
      variantCount: variantCount,
    );

    await saveVariants(examId, variants);
    return variants;
  }
}
