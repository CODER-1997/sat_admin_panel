import 'package:cloud_firestore/cloud_firestore.dart';

import 'parse.dart';

/// users/{uid}/lessonProgress/{lessonId}
class LessonProgress {
  LessonProgress({
    required this.lessonId,
    this.completed = false,
    this.positionSec = 0,
  });

  final String lessonId;
  final bool completed;
  final int positionSec;

  factory LessonProgress.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return LessonProgress(
      lessonId: d.id,
      completed: parseBool(m['completed']),
      positionSec: parseInt(m['positionSec']),
    );
  }
}
