import '../models/sat_module.dart';
import '../models/sat_question.dart';
import '../models/sat_test.dart';
import '../models/test_attempt.dart';

/// Test natijasini hisoblash.
///
/// MUHIM: haqiqiy Digital SAT ballari IRT (adaptiv, savol qiyinligiga qarab)
/// asosida hisoblanadi va uning jadvali ochiq emas. Bu yerda taxminiy chiziqli
/// shkala ishlatiladi: bo'lim bali = 200 + 600 * (to'g'ri / jami), 10 ga
/// yaxlitlanadi; umumiy = Reading&Writing + Math (400-1600).
class SatScoring {
  SatScoring._();

  static int scale(int correct, int total) {
    if (total <= 0) return 200;
    final raw = 200 + 600 * correct / total;
    return ((raw / 10).round() * 10).clamp(200, 800).toInt();
  }

  static double? _num(String s) {
    final t = s.trim().replaceAll(' ', '').replaceAll(',', '.');
    if (t.isEmpty) return null;
    if (t.contains('/')) {
      final p = t.split('/');
      if (p.length == 2) {
        final a = double.tryParse(p[0]);
        final b = double.tryParse(p[1]);
        if (a != null && b != null && b != 0) return a / b;
      }
      return null;
    }
    return double.tryParse(t);
  }

  static String _norm(String s) => s.trim().toLowerCase().replaceAll(' ', '');

  static bool isCorrect(SatQuestion q, String? answer) {
    if (answer == null || answer.trim().isEmpty) return false;
    if (q.isMultipleChoice) {
      return int.tryParse(answer) == q.correctIndex;
    }
    final given = _num(answer);
    for (final acc in q.acceptedAnswers) {
      final n = _num(acc);
      if (given != null && n != null) {
        if ((given - n).abs() < 1e-9) return true;
      } else if (_norm(answer) == _norm(acc)) {
        return true;
      }
    }
    return false;
  }

  static List<SatModule> sortModules(Iterable<SatModule> modules) {
    final l = modules.where((m) => m.questions.isNotEmpty).toList();
    l.sort((a, b) => a.sortKey.compareTo(b.sortKey));
    return l;
  }

  static TestAttempt grade({
    required String attemptId,
    required String uid,
    required String userName,
    required SatTest test,
    required List<SatModule> modules,
    required Map<String, String> answers,
    required DateTime startedAt,
  }) {
    var rwC = 0, rwT = 0, mC = 0, mT = 0;
    final results = <Map<String, dynamic>>[];

    for (final m in modules) {
      var c = 0;
      for (final q in m.questions) {
        if (isCorrect(q, answers[q.id])) c++;
      }
      if (m.section == SatModule.rw) {
        rwC += c;
        rwT += m.questions.length;
      } else {
        mC += c;
        mT += m.questions.length;
      }
      results.add({
        'moduleId': m.id,
        'label': m.label,
        'correct': c,
        'total': m.questions.length,
      });
    }

    final rwScore = rwT > 0 ? scale(rwC, rwT) : null;
    final mathScore = mT > 0 ? scale(mC, mT) : null;
    final total = (rwScore != null && mathScore != null)
        ? rwScore + mathScore
        : null;

    return TestAttempt(
      id: attemptId,
      uid: uid,
      userName: userName,
      testId: test.id,
      testTitle: test.title,
      answers: answers,
      rwCorrect: rwC,
      rwTotal: rwT,
      mathCorrect: mC,
      mathTotal: mT,
      rwScore: rwScore,
      mathScore: mathScore,
      totalScore: total,
      moduleResults: results,
      startedAt: startedAt,
      finishedAt: DateTime.now(),
    );
  }
}
