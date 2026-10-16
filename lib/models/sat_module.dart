import 'package:cloud_firestore/cloud_firestore.dart';

import 'parse.dart';
import 'sat_question.dart';

/// tests/{testId}/modules/{id}
class SatModule {
  SatModule({
    this.id = '',
    required this.testId,
    required this.section,
    required this.moduleNo,
    this.title = '',
    this.durationMin = 32,
    this.questions = const [],
  });

  static const rw = 'rw';
  static const math = 'math';

  /// Digital SAT: Reading & Writing modul = 32 daqiqa (27 savol),
  /// Math modul = 35 daqiqa (22 savol).
  static int defaultMinutes(String section) => section == rw ? 32 : 35;
  static int defaultQuestionCount(String section) => section == rw ? 27 : 22;

  final String id;
  final String testId;
  final String section;
  final int moduleNo; // 1 yoki 2
  final String title;
  final int durationMin;
  final List<SatQuestion> questions;

  String get sectionLabel => section == rw ? 'Reading & Writing' : 'Math';
  String get label => '$sectionLabel · $moduleNo-modul';
  int get sortKey => (section == rw ? 0 : 10) + moduleNo;

  factory SatModule.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    final qs = m['questions'] is List
        ? (m['questions'] as List)
            .whereType<Map>()
            .map((e) => SatQuestion.fromMap(Map<String, dynamic>.from(e)))
            .toList()
        : <SatQuestion>[];
    return SatModule(
      id: d.id,
      testId: parseStr(m['testId']),
      section: parseStr(m['section'], rw),
      moduleNo: parseInt(m['moduleNo'], 1),
      title: parseStr(m['title']),
      durationMin: parseInt(m['durationMin'], 32),
      questions: qs,
    );
  }

  Map<String, dynamic> toMap() => {
        'testId': testId,
        'section': section,
        'moduleNo': moduleNo,
        'title': title,
        'durationMin': durationMin,
        'questionCount': questions.length,
        'questions': questions.map((q) => q.toMap()).toList(),
      };

  SatModule copyWith({
    String? section,
    int? moduleNo,
    String? title,
    int? durationMin,
    List<SatQuestion>? questions,
  }) =>
      SatModule(
        id: id,
        testId: testId,
        section: section ?? this.section,
        moduleNo: moduleNo ?? this.moduleNo,
        title: title ?? this.title,
        durationMin: durationMin ?? this.durationMin,
        questions: questions ?? this.questions,
      );
}
