import 'package:cloud_firestore/cloud_firestore.dart';

import 'parse.dart';

/// tests/{id}
class SatTest {
  SatTest({
    this.id = '',
    required this.title,
    this.description = '',
    this.published = false,
    this.questionCount = 0,
    this.durationMin = 0,
    this.moduleCount = 0,
    this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final bool published;
  final int questionCount;
  final int durationMin;
  final int moduleCount;
  final DateTime? createdAt;

  factory SatTest.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return SatTest(
      id: d.id,
      title: parseStr(m['title']),
      description: parseStr(m['description']),
      published: parseBool(m['published']),
      questionCount: parseInt(m['questionCount']),
      durationMin: parseInt(m['durationMin']),
      moduleCount: parseInt(m['moduleCount']),
      createdAt: parseDate(m['createdAt']),
    );
  }

  /// Hisoblangan maydonlar (savol soni, davomiylik) bu yerga kirmaydi.
  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'published': published,
      };
}
