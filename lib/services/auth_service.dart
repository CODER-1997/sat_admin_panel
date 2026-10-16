import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? db})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  Stream<User?> get authChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);

  /// Yangi talaba: Auth foydalanuvchisi + users/{uid} hujjati (role = student).
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = cred.user!;
    await user.updateDisplayName(name.trim());
    await _db.collection('users').doc(user.uid).set({
      'name': name.trim(),
      'email': email.trim(),
      'role': 'student',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> signOut() => _auth.signOut();

  Future<AppUser?> fetchUser(String uid) async {
    final d = await _db.collection('users').doc(uid).get();
    return d.exists ? AppUser.fromDoc(d) : null;
  }

  /// Firebase xatolarini o'zbekcha matnga aylantiradi.
  static String message(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          return "Email yoki parol noto'g'ri";
        case 'invalid-email':
          return "Email manzili noto'g'ri";
        case 'email-already-in-use':
          return "Bu email allaqachon ro'yxatdan o'tgan";
        case 'weak-password':
          return "Parol kamida 6 ta belgidan iborat bo'lsin";
        case 'network-request-failed':
          return "Internet aloqasi yo'q";
        case 'too-many-requests':
          return "Juda ko'p urinish. Birozdan so'ng qayta urinib ko'ring";
        case 'user-disabled':
          return "Bu akkaunt bloklangan";
      }
      return e.message ?? 'Xatolik: ${e.code}';
    }
    return e.toString();
  }
}
