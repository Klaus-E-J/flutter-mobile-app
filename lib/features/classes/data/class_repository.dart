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
