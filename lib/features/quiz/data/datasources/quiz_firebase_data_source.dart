import 'package:firebase_database/firebase_database.dart';

import '../../domain/entities/question.dart';

abstract class QuizFirebaseDataSource {
  Future<String> saveQuizResult({
    required String topic,
    required String quizType,
    required int score,
    required int totalQuestions,
    required DateTime date,
    required List<int> answers,
    required List<Question> questions,
  });

  Future<Map<String, dynamic>> getQuizResultById(String id);
}

class QuizFirebaseDataSourceImpl implements QuizFirebaseDataSource {
  const QuizFirebaseDataSourceImpl();

  @override
  Future<String> saveQuizResult({
    required String topic,
    required String quizType,
    required int score,
    required int totalQuestions,
    required DateTime date,
    required List<int> answers,
    required List<Question> questions,
  }) async {
    final ref = FirebaseDatabase.instance.ref().child('quiz_results').push();
    final id = ref.key;

    final quizData = {
      'topic': topic,
      'quizType': quizType,
      'score': score,
      'totalQuestions': totalQuestions,
      'percentage': ((score / totalQuestions) * 100).round(),
      'date': date.toIso8601String(),
      'answers': answers,
      'questions': questions
          .map(
            (q) => {
              'id': q.id,
              'question': q.question,
              'options': q.options,
              'correctAnswer': q.correctAnswer,
              'explanation': q.explanation,
            },
          )
          .toList(),
    };

    await ref.set(quizData);

    if (id == null) {
      throw Exception('Failed to generate Firebase record key');
    }

    return id;
  }

  @override
  Future<Map<String, dynamic>> getQuizResultById(String id) async {
    final snapshot = await FirebaseDatabase.instance
        .ref()
        .child('quiz_results')
        .child(id)
        .get();

    if (!snapshot.exists || snapshot.value == null) {
      throw Exception('Result not found in Firebase');
    }

    final value = snapshot.value;
    if (value is Map) {
      return _normalizeMap(value);
    }

    throw Exception('Unexpected Firebase data format');
  }

  Map<String, dynamic> _normalizeMap(Map<dynamic, dynamic> raw) {
    return raw.map((key, value) {
      final normalizedKey = key.toString();
      final normalizedValue = _normalizeValue(value);
      return MapEntry(normalizedKey, normalizedValue);
    });
  }

  dynamic _normalizeValue(dynamic value) {
    if (value is Map) {
      return _normalizeMap(value.cast<dynamic, dynamic>());
    }
    if (value is List) {
      return value.map(_normalizeValue).toList();
    }
    return value;
  }
}
