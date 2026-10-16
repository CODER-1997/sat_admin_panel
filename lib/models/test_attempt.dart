import 'package:cloud_firestore/cloud_firestore.dart';

import 'parse.dart';

/// users/{uid}/attempts/{id}
class TestAttempt {
  TestAttempt({
    required this.id,
    required this.uid,
    this.userName = '',
    required this.testId,
    required this.testTitle,
    required this.answers,
    required this.rwCorrect,
    required this.rwTotal,
    required this.mathCorrect,
    required this.mathTotal,
    this.rwScore,
    this.mathScore,
    this.totalScore,
    this.moduleResults = const [],
    required this.startedAt,
    required this.finishedAt,
  });

  final String id;
  final String uid;
  final String userName;
  final String testId;
  final String testTitle;
  final Map<String, String> answers; // savolId -> javob
  final int rwCorrect;
  final int rwTotal;
  final int mathCorrect;
  final int mathTotal;
  final int? rwScore; // 200-800
  final int? mathScore; // 200-800
  final int? totalScore; // 400-1600
  final List<Map<String, dynamic>> moduleResults;
  final DateTime startedAt;
  final DateTime finishedAt;

  int get correct => rwCorrect + mathCorrect;
  int get total => rwTotal + mathTotal;
  double get accuracy => total == 0 ? 0 : correct / total;

  factory TestAttempt.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    final ans = <String, String>{};
    if (m['answers'] is Map) {
      (m['answers'] as Map).forEach((k, v) => ans[k.toString()] = v.toString());
    }
    final mr = m['moduleResults'] is List
        ? (m['moduleResults'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : <Map<String, dynamic>>[];
    return TestAttempt(
      id: d.id,
      uid: parseStr(m['uid']),
      userName: parseStr(m['userName']),
      testId: parseStr(m['testId']),
      testTitle: parseStr(m['testTitle']),
      answers: ans,
      rwCorrect: parseInt(m['rwCorrect']),
      rwTotal: parseInt(m['rwTotal']),
      mathCorrect: parseInt(m['mathCorrect']),
      mathTotal: parseInt(m['mathTotal']),
      rwScore: m['rwScore'] is num ? (m['rwScore'] as num).toInt() : null,
      mathScore: m['mathScore'] is num ? (m['mathScore'] as num).toInt() : null,
      totalScore:
          m['totalScore'] is num ? (m['totalScore'] as num).toInt() : null,
      moduleResults: mr,
      startedAt: parseDate(m['startedAt']) ?? DateTime.now(),
      finishedAt: parseDate(m['finishedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'userName': userName,
        'testId': testId,
        'testTitle': testTitle,
        'answers': answers,
        'rwCorrect': rwCorrect,
        'rwTotal': rwTotal,
        'mathCorrect': mathCorrect,
        'mathTotal': mathTotal,
        'rwScore': rwScore,
        'mathScore': mathScore,
        'totalScore': totalScore,
        'moduleResults': moduleResults,
        'startedAt': Timestamp.fromDate(startedAt),
        'finishedAt': Timestamp.fromDate(finishedAt),
      };
}
