/// Firestore'dan kelgan qiymatlarni xavfsiz o'qish uchun kichik yordamchilar.
import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? parseDate(dynamic v) => v is Timestamp ? v.toDate() : null;
String parseStr(dynamic v, [String d = '']) => v is String ? v : d;
String? parseStrOrNull(dynamic v) => (v is String && v.isNotEmpty) ? v : null;
int parseInt(dynamic v, [int d = 0]) => v is num ? v.toInt() : d;
bool parseBool(dynamic v, [bool d = false]) => v is bool ? v : d;
List<String> parseStrList(dynamic v) =>
    v is List ? v.map((e) => e.toString()).toList() : <String>[];
