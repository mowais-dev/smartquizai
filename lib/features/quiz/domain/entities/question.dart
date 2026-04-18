import 'package:equatable/equatable.dart';

class Question extends Equatable {
  const Question({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswer,
    this.explanation,
  });

  final String id;
  final String question;
  final List<String> options;
  final int correctAnswer;
  final String? explanation;

  @override
  List<Object?> get props => [
    id,
    question,
    options,
    correctAnswer,
    explanation,
  ];
}

class Quiz extends Equatable {
  const Quiz({
    required this.id,
    required this.topic,
    required this.questions,
    required this.createdAt,
  });

  final String id;
  final String topic;
  final List<Question> questions;
  final DateTime createdAt;

  int get totalQuestions => questions.length;

  @override
  List<Object?> get props => [id, topic, questions, createdAt];
}

class QuizResult extends Equatable {
  const QuizResult({
    required this.quizId,
    required this.topic,
    required this.score,
    required this.totalQuestions,
    required this.completedAt,
    required this.answers,
    required this.questions,
  });

  final String quizId;
  final String topic;
  final int score;
  final int totalQuestions;
  final DateTime completedAt;
  final List<int> answers; // User's selected answers
  final List<Question> questions; // Full question details

  int get percentage => ((score / totalQuestions) * 100).round();

  bool get isPassed => percentage >= 60; // 60% passing grade

  @override
  List<Object?> get props => [
    quizId,
    topic,
    score,
    totalQuestions,
    completedAt,
    answers,
    questions,
  ];
}

class QuizHistory extends Equatable {
  const QuizHistory({
    required this.id,
    required this.topic,
    required this.score,
    required this.totalQuestions,
    required this.date,
    required this.percentage,
  });

  final String id;
  final String topic;
  final int score;
  final int totalQuestions;
  final DateTime date;
  final int percentage;

  @override
  List<Object?> get props => [
    id,
    topic,
    score,
    totalQuestions,
    date,
    percentage,
  ];
}
