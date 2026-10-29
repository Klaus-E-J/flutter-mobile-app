import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/firebase_service.dart';
import '../../../screens/provas/models/questao_model.dart';

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
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
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

  Future<String> saveExam({
    String? id,
    required String title,
    required List<String> classIds,
    required List<String> classNames,
    required bool sameExamForEveryone,
  }) async {
    final reference = id == null ? _exams.doc() : _exams.doc(id);
    final data = <String, dynamic>{
      'title': title.trim(),
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
    return reference.id;
  }

  Stream<List<Questao>> watchQuestions(String examId) => _exams
      .doc(examId)
      .collection('questions')
      .orderBy('order')
      .snapshots()
      .map((snapshot) => snapshot.docs.map(_questionFromDocument).toList());

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
    final batch = FirebaseService.firestore.batch();

    final retainedIds = questions.map((question) => question.id).toSet();
    for (final document in existing.docs) {
      if (!retainedIds.contains(document.id)) {
        batch.delete(document.reference);
      }
    }
    for (var index = 0; index < questions.length; index++) {
      final question = questions[index];
      batch.set(questionsReference.doc(question.id), {
        'statement': question.enunciado.trim(),
        'order': index,
        'alternatives': question.alternativas.map((alternative) => {
          'id': alternative.id,
          'text': alternative.texto.trim(),
          'correct': alternative.correta,
        }).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    batch.update(examReference, {
      'questionCount': questions.length,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }
}
