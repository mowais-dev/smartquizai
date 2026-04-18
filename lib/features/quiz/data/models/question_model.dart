import '../../domain/entities/question.dart';

class QuestionModel extends Question {
  const QuestionModel({
    required super.id,
    required super.question,
    required super.options,
    required super.correctAnswer,
    super.explanation,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] as String,
      question: json['question'] as String,
      options: List<String>.from(json['options'] as List),
      correctAnswer: json['correctAnswer'] as int,
      explanation: json['explanation'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
    };
  }

  factory QuestionModel.fromEntity(Question question) {
    return QuestionModel(
      id: question.id,
      question: question.question,
      options: question.options,
      correctAnswer: question.correctAnswer,
      explanation: question.explanation,
    );
  }
}

class QuizModel {
  const QuizModel({
    required this.id,
    required this.topic,
    required this.questions,
    required this.createdAt,
  });

  final String id;
  final String topic;
  final List<QuestionModel> questions;
  final DateTime createdAt;

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    return QuizModel(
      id: json['id'] as String,
      topic: json['topic'] as String,
      questions: (json['questions'] as List)
          .map((q) => QuestionModel.fromJson(q as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'topic': topic,
      'questions': questions.map((q) => q.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class QuizResultModel {
  const QuizResultModel({
    required this.quizId,
    required this.topic,
    required this.score,
    required this.totalQuestions,
    required this.completedAt,
    required this.answers,
  });

  final String quizId;
  final String topic;
  final int score;
  final int totalQuestions;
  final DateTime completedAt;
  final List<int> answers;

  factory QuizResultModel.fromJson(Map<String, dynamic> json) {
    return QuizResultModel(
      quizId: json['quizId'] as String,
      topic: json['topic'] as String,
      score: json['score'] as int,
      totalQuestions: json['totalQuestions'] as int,
      completedAt: DateTime.parse(json['completedAt'] as String),
      answers: List<int>.from(json['answers'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quizId': quizId,
      'topic': topic,
      'score': score,
      'totalQuestions': totalQuestions,
      'completedAt': completedAt.toIso8601String(),
      'answers': answers,
    };
  }
}
