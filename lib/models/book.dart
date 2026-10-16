import 'package:cloud_firestore/cloud_firestore.dart';

import 'parse.dart';

/// books/{id}
class Book {
  Book({
    this.id = '',
    required this.title,
    this.author = '',
    this.description = '',
    this.coverKey,
    this.pdfKey,
    this.published = true,
    this.createdAt,
  });

  final String id;
  final String title;
  final String author;
  final String description;
  final String? coverKey;
  final String? pdfKey;
  final bool published;
  final DateTime? createdAt;

  factory Book.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return Book(
      id: d.id,
      title: parseStr(m['title']),
      author: parseStr(m['author']),
      description: parseStr(m['description']),
      coverKey: parseStrOrNull(m['coverKey']),
      pdfKey: parseStrOrNull(m['pdfKey']),
      published: parseBool(m['published'], true),
      createdAt: parseDate(m['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'author': author,
        'description': description,
        'coverKey': coverKey,
        'pdfKey': pdfKey,
        'published': published,
      };
}
