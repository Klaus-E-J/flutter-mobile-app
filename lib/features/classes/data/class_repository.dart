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
  const StudentRecord({required this.id, required this.name});

  final String id;
  final String name;

  factory StudentRecord.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) => StudentRecord(id: document.id, name: document.data()['name'] as String? ?? '');
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

  Future<void> addStudent({required String classId, required String name}) async {
    final classReference = _classes.doc(classId);
    final studentReference = classReference.collection('students').doc();
    await FirebaseService.firestore.runTransaction((transaction) async {
      final classSnapshot = await transaction.get(classReference);
      if (!classSnapshot.exists) {
        throw StateError('A turma não existe mais. Atualize a lista e tente novamente.');
      }
      transaction.set(studentReference, {
        'name': name.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.update(classReference, {
        'studentCount': ((classSnapshot.data()?['studentCount'] as num?)?.toInt() ?? 0) + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> addStudents({required String classId, required List<String> names}) async {
    final cleanedNames = names.map((name) => name.trim()).where((name) => name.isNotEmpty).toList();
    if (cleanedNames.isEmpty) return;
    final classReference = _classes.doc(classId);
    final batch = FirebaseService.firestore.batch();
    for (final name in cleanedNames) {
      final studentReference = classReference.collection('students').doc();
      batch.set(studentReference, {
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    batch.update(classReference, {
      'studentCount': FieldValue.increment(cleanedNames.length),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }
}
