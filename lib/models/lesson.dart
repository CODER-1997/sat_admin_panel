import 'package:cloud_firestore/cloud_firestore.dart';

import 'parse.dart';

/// lessons/{id}
class Lesson {
  Lesson({
    this.id = '',
    required this.courseId,
    required this.title,
    this.description = '',
    this.videoKey,
    this.durationMin = 0,
    this.order = 0,
    this.published = true,
  });

  final String id;
  final String courseId;
  final String title;
  final String description;
  final String? videoKey;
  final int durationMin;
  final int order;
  final bool published;

  factory Lesson.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return Lesson(
      id: d.id,
      courseId: parseStr(m['courseId']),
      title: parseStr(m['title']),
      description: parseStr(m['description']),
      videoKey: parseStrOrNull(m['videoKey']),
      durationMin: parseInt(m['durationMin']),
      order: parseInt(m['order']),
      published: parseBool(m['published'], true),
    );
  }

  Map<String, dynamic> toMap() => {
        'courseId': courseId,
        'title': title,
        'description': description,
        'videoKey': videoKey,
        'durationMin': durationMin,
        'order': order,
        'published': published,
      };
}
