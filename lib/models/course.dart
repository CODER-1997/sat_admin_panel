import 'package:cloud_firestore/cloud_firestore.dart';

import 'parse.dart';

/// courses/{id}
class Course {
  Course({
    this.id = '',
    required this.title,
    this.description = '',
    this.coverKey,
    this.published = true,
    this.order = 0,
    this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final String? coverKey;
  final bool published;
  final int order;
  final DateTime? createdAt;

  factory Course.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return Course(
      id: d.id,
      title: parseStr(m['title']),
      description: parseStr(m['description']),
      coverKey: parseStrOrNull(m['coverKey']),
      published: parseBool(m['published'], true),
      order: parseInt(m['order']),
      createdAt: parseDate(m['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'coverKey': coverKey,
        'published': published,
        'order': order,
      };
}
