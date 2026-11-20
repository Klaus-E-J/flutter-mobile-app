import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/firebase_service.dart';
import '../../../screens/provas/models/questao_model.dart';
import '../../classes/data/class_repository.dart';
import '../models/exam_application_mode.dart';
import '../models/exam_variant.dart';
import '../services/exam_randomizer_service.dart';

class ExamRecord {
  const ExamRecord({
    required this.id,
    required this.title,
    required this.classIds,
    required this.classNames,
    required this.applicationMode,
    required this.questionCount,
  });

  final String id;
  final String title;
  final List<String> classIds;
  final List<String> classNames;
  final ExamApplicationMode applicationMode;
  final int questionCount;

  /// Atalho legado: `true` quando todos recebem a mesma prova.
  bool get sameExamForEveryone => applicationMode.sameExamForEveryone;

  factory ExamRecord.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    return ExamRecord(
      id: document.id,
      title: data['title'] as String? ?? '',
      classIds: (data['classIds'] as List<dynamic>? ?? const []).whereType<String>().toList(),
      classNames: (data['classNames'] as List<dynamic>? ?? const []).whereType<String>().toList(),
      applicationMode: ExamApplicationMode.fromStored(
        data['applicationMode'],
        legacySameForEveryone: data['sameExamForEveryone'] as bool?,
      ),
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
    required ExamApplicationMode applicationMode,
  }) async {
    final trimmedTitle = title.trim();
    final reference = id == null ? _exams.doc() : _exams.doc(id);
    final data = <String, dynamic>{
      'title': trimmedTitle,
      'classId': classIds.isNotEmpty ? classIds.first : '',
      'className': classNames.isNotEmpty ? classNames.first : '',
      'classIds': classIds,
      'classNames': classNames,
      'applicationMode': applicationMode.id,
      // Campo legado, mantido para versões antigas do app.
      'sameExamForEveryone': applicationMode.sameExamForEveryone,
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

  /// Mantido por compatibilidade: apenas sincroniza (não reembaralha).
  Future<List<ExamVariant>> regenerateVariantsForExam({
    required String examId,
    List<Questao>? questions,
  }) {
    return syncVariants(examId: examId, questions: questions);
  }

  /// Garante que a prova tenha variantes para todos os alunos das turmas
  /// vinculadas, **sem alterar variantes já existentes** enquanto o modo de
  /// aplicação, a semente e as questões continuarem os mesmos.
  ///
  /// - Renomear a prova, trocar turmas ou incluir/remover alunos nunca muda
  ///   a prova (ordem e gabarito) dos alunos que já tinham variante.
  /// - Variantes de todas as turmas são consideradas juntas: corrigir uma
  ///   turma não apaga as variantes das outras.
  /// - [reshuffle] = `true` sorteia uma nova semente (ação explícita do
  ///   professor), que fica salva na prova e passa a valer daí em diante.
  Future<List<ExamVariant>> syncVariants({
    required String examId,
    List<Questao>? questions,
    bool reshuffle = false,
  }) async {
    final examRef = _exams.doc(examId);
    final examDoc = await examRef.get();
    if (!examDoc.exists) return const [];
    final exam = ExamRecord.fromDocument(examDoc);
    final examQuestions = questions ?? await getQuestions(examId);
    if (examQuestions.isEmpty) return const [];

    final mode = exam.applicationMode;
    var seed = (examDoc.data()?['variantSeed'] as num?)?.toInt() ??
        ExamRandomizerService.defaultSeedFor(examId);
    if (reshuffle) {
      seed = Random.secure().nextInt(1 << 31);
      await examRef.update({
        'variantSeed': seed,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    final students = mode.perStudent && exam.classIds.isNotEmpty
        ? await ClassRepository().getStudentsForClasses(
            classIds: exam.classIds,
            classNames: exam.classNames,
          )
        : const <StudentRecord>[];

    const randomizer = ExamRandomizerService();
    final generated = randomizer.generateVariantsForMode(
      examId: examId,
      questions: examQuestions,
      mode: mode,
      students: students,
      classId: exam.classIds.isNotEmpty ? exam.classIds.first : null,
      className: exam.classNames.isNotEmpty ? exam.classNames.first : null,
      seed: seed,
    );
    final fingerprint = ExamRandomizerService.configFingerprint(
      mode: mode,
      seed: seed,
      questions: examQuestions,
    );

    final existing = await getVariants(examId);
    final merged = randomizer.mergeWithExisting(
      generated: generated,
      existing: existing,
      fingerprint: fingerprint,
      // Variantes de versões anteriores só são reaproveitadas enquanto o
      // professor não pedir um novo embaralhamento.
      legacyQuestions: reshuffle ? null : examQuestions,
    );

    if (!_sameVariants(existing, merged)) {
      await saveVariants(examId, merged);
    }
    return merged;
  }

  static bool _sameVariants(List<ExamVariant> a, List<ExamVariant> b) {
    if (a.length != b.length) return false;
    String encode(List<ExamVariant> list) {
      final sorted = [...list]..sort((x, y) => x.id.compareTo(y.id));
      return jsonEncode([
        for (final v in sorted) {'id': v.id, ...v.toMap()},
      ]);
    }

    return encode(a) == encode(b);
  }
}
