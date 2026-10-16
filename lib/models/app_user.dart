import 'package:cloud_firestore/cloud_firestore.dart';

import 'parse.dart';

/// users/{uid}
class AppUser {
  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.role = 'student',
    this.createdAt,
  });

  final String uid;
  final String name;
  final String email;
  final String role; // 'admin' | 'student'
  final DateTime? createdAt;

  bool get isAdmin => role == 'admin';

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return AppUser(
      uid: d.id,
      name: parseStr(m['name']),
      email: parseStr(m['email']),
      role: parseStr(m['role'], 'student'),
      createdAt: parseDate(m['createdAt']),
    );
  }
}
