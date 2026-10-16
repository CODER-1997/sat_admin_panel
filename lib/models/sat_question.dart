import 'parse.dart';

/// Bitta SAT savoli (modul hujjati ichida saqlanadi).
class SatQuestion {
  SatQuestion({
    required this.id,
    this.type = 'mc',
    this.passage = '',
    required this.prompt,
    this.imageKey,
    this.choices = const ['', '', '', ''],
    this.correctIndex = 0,
    this.acceptedAnswers = const [],
    this.explanation = '',
  });

  static const mc = 'mc'; // 4 variantli test
  static const spr = 'spr'; // student-produced response (Math, javob yoziladi)

  final String id;
  final String type;
  final String passage; // Reading & Writing matni
  final String prompt; // savol matni
  final String? imageKey;
  final List<String> choices;
  final int correctIndex;
  final List<String> acceptedAnswers;
  final String explanation;

  bool get isMultipleChoice => type == mc;

  String get correctText {
    if (isMultipleChoice) {
      if (correctIndex < 0 || correctIndex >= choices.length) return '-';
      return '${String.fromCharCode(65 + correctIndex)}) ${choices[correctIndex]}';
    }
    return acceptedAnswers.join('  yoki  ');
  }

  factory SatQuestion.fromMap(Map<String, dynamic> m) {
    final ch = parseStrList(m['choices']);
    while (ch.length < 4) {
      ch.add('');
    }
    return SatQuestion(
      id: parseStr(m['id']),
      type: parseStr(m['type'], mc),
      passage: parseStr(m['passage']),
      prompt: parseStr(m['prompt']),
      imageKey: parseStrOrNull(m['imageKey']),
      choices: ch,
      correctIndex: parseInt(m['correctIndex']),
      acceptedAnswers: parseStrList(m['acceptedAnswers']),
      explanation: parseStr(m['explanation']),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'passage': passage,
        'prompt': prompt,
        'imageKey': imageKey,
        'choices': choices,
        'correctIndex': correctIndex,
        'acceptedAnswers': acceptedAnswers,
        'explanation': explanation,
      };
}
