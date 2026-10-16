import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/book.dart';
import '../models/course.dart';
import '../models/lesson.dart';
import '../models/lesson_progress.dart';
import '../models/sat_module.dart';
import '../models/sat_test.dart';
import '../models/test_attempt.dart';
import 'scoring.dart';

typedef _Doc = DocumentSnapshot<Map<String, dynamic>>;

/// Firestore bilan ishlovchi yagona joy.
///
/// Eslatma: ro'yxatlar `where(published == true)` bilan olinadi va tartiblash
/// mijoz tomonida bajariladi, shu sababli Firestore'da qo'shimcha composite
/// index yaratish shart emas.
class SatRepository {
  SatRepository({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String name) =>
      _db.collection(name);

  Stream<List<T>> _watch<T>(
    Query<Map<String, dynamic>> q,
    T Function(_Doc) fromDoc,
    int Function(T, T) compare,
  ) =>
      q.snapshots().map((s) {
        final list = s.docs.map<T>((d) => fromDoc(d)).toList();
        list.sort(compare);
        return list;
      });

  Query<Map<String, dynamic>> _maybePublished(String col, bool only) {
    Query<Map<String, dynamic>> q = _col(col);
    if (only) q = q.where('published', isEqualTo: true);
    return q;
  }

  int _newestFirst(DateTime? a, DateTime? b) =>
      (b ?? DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(a ?? DateTime.fromMillisecondsSinceEpoch(0));

  // ------------------------------------------------------------ USERS
  Stream<List<AppUser>> watchStudents() => _watch<AppUser>(
        _col('users').where('role', isEqualTo: 'student'),
        AppUser.fromDoc,
        (a, b) => _newestFirst(a.createdAt, b.createdAt),
      );

  Future<int> count(String collection) async {
    final r = await _col(collection).count().get();
    return r.count ?? 0;
  }

  // ---------------------------------------------------------- COURSES
  Stream<List<Course>> watchCourses({bool onlyPublished = false}) =>
      _watch<Course>(_maybePublished('courses', onlyPublished), Course.fromDoc,
          (a, b) => a.order.compareTo(b.order));

  Future<String> saveCourse(Course c) async {
    final ref = c.id.isEmpty ? _col('courses').doc() : _col('courses').doc(c.id);
    final data = c.toMap();
    if (c.id.isEmpty) data['createdAt'] = FieldValue.serverTimestamp();
    await ref.set(data, SetOptions(merge: true));
    return ref.id;
  }

  /// Kurs va uning darslarini o'chiradi. R2 dan o'chirilishi kerak bo'lgan
  /// fayl kalitlarini qaytaradi.
  Future<List<String>> deleteCourse(String id) async {
    final keys = <String>[];
    final batch = _db.batch();
    final lessons = await _col('lessons').where('courseId', isEqualTo: id).get();
    for (final d in lessons.docs) {
      final k = d.data()['videoKey'];
      if (k is String && k.isNotEmpty) keys.add(k);
      batch.delete(d.reference);
    }
    final cd = await _col('courses').doc(id).get();
    final ck = cd.data()?['coverKey'];
    if (ck is String && ck.isNotEmpty) keys.add(ck);
    batch.delete(_col('courses').doc(id));
    await batch.commit();
    return keys;
  }

  // ---------------------------------------------------------- LESSONS
  Stream<List<Lesson>> watchLessons(String courseId,
          {bool onlyPublished = false}) =>
      _watch<Lesson>(
        _maybePublished('lessons', onlyPublished)
            .where('courseId', isEqualTo: courseId),
        Lesson.fromDoc,
        (a, b) => a.order.compareTo(b.order),
      );

  Future<String> saveLesson(Lesson l) async {
    final ref = l.id.isEmpty ? _col('lessons').doc() : _col('lessons').doc(l.id);
    final data = l.toMap();
    if (l.id.isEmpty) data['createdAt'] = FieldValue.serverTimestamp();
    await ref.set(data, SetOptions(merge: true));
    return ref.id;
  }

  Future<String?> deleteLesson(String id) async {
    final ref = _col('lessons').doc(id);
    final d = await ref.get();
    final k = d.data()?['videoKey'];
    await ref.delete();
    return (k is String && k.isNotEmpty) ? k : null;
  }

  /// Nechta dars borligini kurslar bo'yicha hisoblash (talaba uchun).
  Stream<Map<String, int>> watchLessonCounts() => _col('lessons')
          .where('published', isEqualTo: true)
          .snapshots()
          .map((s) {
        final m = <String, int>{};
        for (final d in s.docs) {
          final id = d.data()['courseId'];
          if (id is String) m[id] = (m[id] ?? 0) + 1;
        }
        return m;
      });

  // ------------------------------------------------------------ BOOKS
  Stream<List<Book>> watchBooks({bool onlyPublished = false}) => _watch<Book>(
        _maybePublished('books', onlyPublished),
        Book.fromDoc,
        (a, b) => _newestFirst(a.createdAt, b.createdAt),
      );

  Future<String> saveBook(Book b) async {
    final ref = b.id.isEmpty ? _col('books').doc() : _col('books').doc(b.id);
    final data = b.toMap();
    if (b.id.isEmpty) data['createdAt'] = FieldValue.serverTimestamp();
    await ref.set(data, SetOptions(merge: true));
    return ref.id;
  }

  Future<List<String>> deleteBook(String id) async {
    final ref = _col('books').doc(id);
    final d = await ref.get();
    final keys = <String>[];
    for (final f in ['coverKey', 'pdfKey']) {
      final k = d.data()?[f];
      if (k is String && k.isNotEmpty) keys.add(k);
    }
    await ref.delete();
    return keys;
  }

  // ------------------------------------------------------------ TESTS
  Stream<List<SatTest>> watchTests({bool onlyPublished = false}) =>
      _watch<SatTest>(
        _maybePublished('tests', onlyPublished),
        SatTest.fromDoc,
        (a, b) => _newestFirst(a.createdAt, b.createdAt),
      );

  Future<String> saveTest(SatTest t) async {
    final ref = t.id.isEmpty ? _col('tests').doc() : _col('tests').doc(t.id);
    final data = t.toMap();
    if (t.id.isEmpty) data['createdAt'] = FieldValue.serverTimestamp();
    await ref.set(data, SetOptions(merge: true));
    return ref.id;
  }

  CollectionReference<Map<String, dynamic>> _modules(String testId) =>
      _col('tests').doc(testId).collection('modules');

  Stream<List<SatModule>> watchModules(String testId) => _watch<SatModule>(
        _modules(testId),
        SatModule.fromDoc,
        (a, b) => a.sortKey.compareTo(b.sortKey),
      );

  /// Talaba uchun: tartiblangan va bo'sh bo'lmagan modullar.
  Future<List<SatModule>> getModules(String testId) async {
    final s = await _modules(testId).get();
    return SatScoring.sortModules(s.docs.map((d) => SatModule.fromDoc(d)));
  }

  Future<String> saveModule(SatModule m) async {
    final ref = m.id.isEmpty ? _modules(m.testId).doc() : _modules(m.testId).doc(m.id);
    await ref.set(m.toMap());
    await _recalcTest(m.testId);
    return ref.id;
  }

  Future<void> deleteModule(String testId, String moduleId) async {
    await _modules(testId).doc(moduleId).delete();
    await _recalcTest(testId);
  }

  Future<void> _recalcTest(String testId) async {
    final s = await _modules(testId).get();
    var q = 0, minutes = 0, count = 0;
    for (final d in s.docs) {
      final m = SatModule.fromDoc(d);
      if (m.questions.isEmpty) continue;
      q += m.questions.length;
      minutes += m.durationMin;
      count++;
    }
    await _col('tests').doc(testId).set(
      {'questionCount': q, 'durationMin': minutes, 'moduleCount': count},
      SetOptions(merge: true),
    );
  }

  /// Testni modullari bilan o'chiradi. Savol rasmlari kalitlarini qaytaradi.
  Future<List<String>> deleteTest(String id) async {
    final keys = <String>[];
    final s = await _modules(id).get();
    final batch = _db.batch();
    for (final d in s.docs) {
      for (final q in SatModule.fromDoc(d).questions) {
        if (q.imageKey != null) keys.add(q.imageKey!);
      }
      batch.delete(d.reference);
    }
    batch.delete(_col('tests').doc(id));
    await batch.commit();
    return keys;
  }

  // --------------------------------------------------------- ATTEMPTS
  String newAttemptId(String uid) =>
      _col('users').doc(uid).collection('attempts').doc().id;

  Future<void> saveAttempt(TestAttempt a) => _col('users')
      .doc(a.uid)
      .collection('attempts')
      .doc(a.id)
      .set(a.toMap());

  Stream<List<TestAttempt>> watchAttempts(String uid) => _watch<TestAttempt>(
        _col('users').doc(uid).collection('attempts'),
        TestAttempt.fromDoc,
        (a, b) => _newestFirst(a.finishedAt, b.finishedAt),
      );

  /// Admin: barcha talabalarning so'nggi urinishlari.
  Future<List<TestAttempt>> recentAttempts({int limit = 100}) async {
    final s = await _db.collectionGroup('attempts').limit(limit).get();
    final list = s.docs.map((d) => TestAttempt.fromDoc(d)).toList();
    list.sort((a, b) => _newestFirst(a.finishedAt, b.finishedAt));
    return list;
  }

  // --------------------------------------------------------- PROGRESS
  Stream<Map<String, LessonProgress>> watchProgress(String uid) =>
      _col('users').doc(uid).collection('lessonProgress').snapshots().map((s) {
        return {
          for (final d in s.docs) d.id: LessonProgress.fromDoc(d),
        };
      });

  Future<void> setProgress(
    String uid,
    String lessonId, {
    bool? completed,
    int? positionSec,
  }) {
    final data = <String, dynamic>{'updatedAt': FieldValue.serverTimestamp()};
    if (completed != null) data['completed'] = completed;
    if (positionSec != null) data['positionSec'] = positionSec;
    return _col('users')
        .doc(uid)
        .collection('lessonProgress')
        .doc(lessonId)
        .set(data, SetOptions(merge: true));
  }
}
