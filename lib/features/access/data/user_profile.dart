import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de domínio do perfil do professor no sistema.
/// Armazenado no Firestore em `users/{uid}`.
class UserProfile {
  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    this.school = '',
    this.accessCode = '',
    this.isAnonymous = false,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String name;
  final String email;
  final String school;
  final String accessCode;
  final bool isAnonymous;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get displayName => name.isNotEmpty ? name : 'Professor';

  factory UserProfile.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    final createdTs = data['createdAt'] as Timestamp?;
    final updatedTs = data['updatedAt'] as Timestamp?;

    return UserProfile(
      uid: snapshot.id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      school: data['school'] as String? ?? '',
      accessCode: data['accessCode'] as String? ?? '',
      isAnonymous: data['isAnonymous'] as bool? ?? false,
      createdAt: createdTs?.toDate(),
      updatedAt: updatedTs?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'school': school.trim(),
      'accessCode': accessCode.trim(),
      'isAnonymous': isAnonymous,
      'updatedAt': FieldValue.serverTimestamp(),
      if (createdAt == null) 'createdAt': FieldValue.serverTimestamp(),
    };
  }

  UserProfile copyWith({
    String? name,
    String? email,
    String? school,
    String? accessCode,
    bool? isAnonymous,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      school: school ?? this.school,
      accessCode: accessCode ?? this.accessCode,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
