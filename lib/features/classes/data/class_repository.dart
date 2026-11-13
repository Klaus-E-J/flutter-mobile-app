import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/firebase_service.dart';

class ClassRecord {
  const ClassRecord({
    required this.id,
    required this.name,
    required this.grade,
    required this.studentCount,
  });

  final String id;
  final String name;
  final String grade;
  final int studentCount;

  factory ClassRecord.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    return ClassRecord(
      id: document.id,
      name: data['name'] as String? ?? '',
      grade: data['grade'] as String? ?? '',
      studentCount: (data['studentCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class StudentRecord {
  const StudentRecord({
    required this.id,
    required this.name,
    this.matricula = '',
    this.email = '',
  });

  final String id;
  final String name;
  final String matricula;
  final String email;

  factory StudentRecord.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    return StudentRecord(
      id: document.id,
      name: data['name'] as String? ?? '',
      matricula: data['matricula'] as String? ?? '',
      email: data['email'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name.trim(),
      'matricula': matricula.trim(),
      'email': email.trim(),
    };
  }
}

class ClassRepository {
  CollectionReference<Map<String, dynamic>> get _classes =>
      FirebaseService.userCollection('classes');

  Stream<List<ClassRecord>> watchClasses() => _classes
      .orderBy('name')
      .snapshots()
      .map((snapshot) => snapshot.docs.map(ClassRecord.fromDocument).toList());

  Future<List<ClassRecord>> getClasses() async {
    final snapshot = await _classes.orderBy('name').get();
    return snapshot.docs.map(ClassRecord.fromDocument).toList();
  }

  Future<String> createClass({required String name, required String grade}) async {
    final reference = _classes.doc();
    await reference.set({
      'name': name.trim(),
      'grade': grade.trim(),
      'studentCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return reference.id;
  }

  Future<void> updateClass({
    required String classId,
    required String name,
    required String grade,
  }) async {
    final trimmedName = name.trim();
    final trimmedGrade = grade.trim();
    final classReference = _classes.doc(classId);

    await classReference.update({
      'name': trimmedName,
      'grade': trimmedGrade,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Sincroniza o nome da turma nas provas vinculadas
    final examsCol = FirebaseService.userCollection('exams');
    final examsSnap = await examsCol.get();
    final pendingUpdates =
        <({DocumentReference<Map<String, dynamic>> ref, Map<String, dynamic> data})>[];

    for (final doc in examsSnap.docs) {
      final data = doc.data();
      final primaryClassId = data['classId'] as String? ?? '';
      final rawIds = data['classIds'];
      final rawNames = data['classNames'];
      final classIds = rawIds is List
          ? rawIds.map((e) => e.toString()).toList()
          : (primaryClassId.isNotEmpty ? <String>[primaryClassId] : <String>[]);
      final classNames = rawNames is List
          ? rawNames.map((e) => e.toString()).toList()
          : <String>[];

      final idx = classIds.indexOf(classId);
      if (primaryClassId == classId || idx != -1) {
        final updates = <String, dynamic>{
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (primaryClassId == classId) {
          updates['className'] = trimmedName;
        }
        if (idx != -1 && idx < classNames.length) {
          final updatedNames = List<String>.from(classNames);
          updatedNames[idx] = trimmedName;
          updates['classNames'] = updatedNames;
          if (idx == 0) {
            updates['className'] = trimmedName;
          }
        }
        pendingUpdates.add((ref: doc.reference, data: updates));
      }
    }

    // Sincroniza o nome da turma nas submissões vinculadas
    final submissionsCol = FirebaseService.userCollection('submissions');
    final subSnap = await submissionsCol.where('classId', isEqualTo: classId).get();
    for (final subDoc in subSnap.docs) {
      pendingUpdates.add((
        ref: subDoc.reference,
        data: <String, dynamic>{'className': trimmedName},
      ));
    }

    const batchSize = 400;
    for (var i = 0; i < pendingUpdates.length; i += batchSize) {
      final end = (i + batchSize < pendingUpdates.length)
          ? i + batchSize
          : pendingUpdates.length;
      final batch = FirebaseService.firestore.batch();
      for (final item in pendingUpdates.sublist(i, end)) {
        batch.update(item.ref, item.data);
      }
      await batch.commit();
    }
  }

  Future<void> deleteClass(String classId) async {
    final classReference = _classes.doc(classId);
    final studentsSnapshot = await classReference.collection('students').get();

    const batchSize = 400;
    final studentDocs = studentsSnapshot.docs;
    for (var i = 0; i < studentDocs.length; i += batchSize) {
      final end = (i + batchSize < studentDocs.length)
          ? i + batchSize
          : studentDocs.length;
      final batch = FirebaseService.firestore.batch();
      for (final doc in studentDocs.sublist(i, end)) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }

    await classReference.delete();
  }

  Stream<List<StudentRecord>> watchStudents(String classId) => _classes
      .doc(classId)
      .collection('students')
      .orderBy('name')
      .snapshots()
      .map((snapshot) => snapshot.docs.map(StudentRecord.fromDocument).toList());

  Future<List<StudentRecord>> getStudents(String classId) async {
    final snapshot = await _classes
        .doc(classId)
        .collection('students')
        .orderBy('name')
        .get();
    return snapshot.docs.map(StudentRecord.fromDocument).toList();
  }

  Future<void> addStudent({
    required String classId,
    required String name,
    String matricula = '',
    String email = '',
  }) async {
    final classReference = _classes.doc(classId);
    final studentReference = classReference.collection('students').doc();
    await FirebaseService.firestore.runTransaction((transaction) async {
      final classSnapshot = await transaction.get(classReference);
      if (!classSnapshot.exists) {
        throw StateError('A turma não existe mais. Atualize a lista e tente novamente.');
      }
      transaction.set(studentReference, {
        'name': name.trim(),
        'matricula': matricula.trim(),
        'email': email.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.update(classReference, {
        'studentCount': ((classSnapshot.data()?['studentCount'] as num?)?.toInt() ?? 0) + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> updateStudent({
    required String classId,
    required String studentId,
    required String name,
    String matricula = '',
    String email = '',
  }) async {
    final trimmedName = name.trim();
    final studentReference = _classes
        .doc(classId)
        .collection('students')
        .doc(studentId);

    await studentReference.update({
      'name': trimmedName,
      'matricula': matricula.trim(),
      'email': email.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final submissionsCol = FirebaseService.userCollection('submissions');
    final subSnap = await submissionsCol
        .where('classId', isEqualTo: classId)
        .where('studentId', isEqualTo: studentId)
        .get();
    const batchSize = 400;
    final subDocs = subSnap.docs;
    for (var i = 0; i < subDocs.length; i += batchSize) {
      final end = (i + batchSize < subDocs.length)
          ? i + batchSize
          : subDocs.length;
      final batch = FirebaseService.firestore.batch();
      for (final doc in subDocs.sublist(i, end)) {
        batch.update(doc.reference, {'studentName': trimmedName});
      }
      await batch.commit();
    }
  }

  Future<void> deleteStudent({
    required String classId,
    required String studentId,
  }) async {
    final classReference = _classes.doc(classId);
    final studentReference = classReference.collection('students').doc(studentId);

    await FirebaseService.firestore.runTransaction((transaction) async {
      final classSnapshot = await transaction.get(classReference);
      final studentSnapshot = await transaction.get(studentReference);
      if (!studentSnapshot.exists) return;

      transaction.delete(studentReference);
      if (classSnapshot.exists) {
        final currentCount =
            (classSnapshot.data()?['studentCount'] as num?)?.toInt() ?? 0;
        final nextCount = currentCount > 0 ? currentCount - 1 : 0;
        transaction.update(classReference, {
          'studentCount': nextCount,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<void> addStudents({
    required String classId,
    List<String> names = const [],
    List<StudentRecord> students = const [],
  }) async {
    final recordsToInsert = <StudentRecord>[
      ...students.where((s) => s.name.trim().isNotEmpty),
      ...names
          .map((name) => name.trim())
          .where((name) => name.isNotEmpty)
          .map((name) => StudentRecord(id: '', name: name)),
    ];
    if (recordsToInsert.isEmpty) return;

    final classReference = _classes.doc(classId);
    const batchSize = 400;

    for (var i = 0; i < recordsToInsert.length; i += batchSize) {
      final end = (i + batchSize < recordsToInsert.length)
          ? i + batchSize
          : recordsToInsert.length;
      final chunk = recordsToInsert.sublist(i, end);
      final batch = FirebaseService.firestore.batch();

      for (final student in chunk) {
        final studentReference = student.id.isNotEmpty
            ? classReference.collection('students').doc(student.id)
            : classReference.collection('students').doc();
        batch.set(studentReference, {
          'name': student.name.trim(),
          'matricula': student.matricula.trim(),
          'email': student.email.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      batch.update(classReference, {
        'studentCount': FieldValue.increment(chunk.length),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
    }
  }
}
