import 'package:dartz/dartz.dart';
import 'dart:typed_data';

import '../../../../core/error/failure.dart';
import '../entities/question.dart';

abstract class QuizRepository {
  Future<Either<Failure, QuizGenerationResult>> generateQuiz(
    String topic, {
    required String difficulty,
    required int questionCount,
    required String quizType,
    Uint8List? imageBytes,
    String? imageMimeType,
    String? documentText,
  });
  Future<Either<Failure, void>> saveQuizResult(
    String topic,
    String quizType,
    int score,
    int totalQuestions,
    List<int> answers,
    List<Question> questions,
  );
  Future<Either<Failure, Map<String, dynamic>>> getQuizResultDetail(String id);
}

class QuizGenerationResult {
  const QuizGenerationResult({
    required this.questions,
    required this.isUsingFallback,
  });

  final List<Question> questions;
  final bool isUsingFallback;
}
