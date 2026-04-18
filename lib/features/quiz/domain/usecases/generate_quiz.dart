import 'package:dartz/dartz.dart';
import 'dart:typed_data';

import '../../../../core/error/failure.dart';
import '../entities/question.dart';
import '../repositories/quiz_repository.dart';

class GenerateQuizUseCase {
  const GenerateQuizUseCase(this.repository);

  final QuizRepository repository;

  Future<Either<Failure, QuizGenerationResult>> call(
    String topic, {
    String difficulty = 'easy',
    int questionCount = 10,
    String quizType = 'text',
    Uint8List? imageBytes,
    String? imageMimeType,
    String? documentText,
  }) async {
    try {
      final isImageQuiz = quizType == 'image';
      final isDocumentQuiz = quizType == 'document';

      if (!isImageQuiz && !isDocumentQuiz && topic.trim().isEmpty) {
        return const Left(ValidationFailure(message: 'Topic cannot be empty'));
      }
      if (isImageQuiz && imageBytes == null) {
        return const Left(
          ValidationFailure(message: 'Please select an image to start the quiz'),
        );
      }
      if (isDocumentQuiz &&
          (documentText == null || documentText.trim().isEmpty)) {
        return const Left(
          ValidationFailure(message: 'Please select a document to start the quiz'),
        );
      }

      return await repository.generateQuiz(
        topic.trim().isEmpty
            ? (isDocumentQuiz ? 'Document Quiz' : 'Image Quiz')
            : topic,
        difficulty: difficulty,
        questionCount: questionCount,
        quizType: quizType,
        imageBytes: imageBytes,
        imageMimeType: imageMimeType,
        documentText: documentText,
      );
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}

class SaveQuizResultUseCase {
  const SaveQuizResultUseCase(this.repository);

  final QuizRepository repository;

  Future<Either<Failure, void>> call({
    required String topic,
    required String quizType,
    required int score,
    required int totalQuestions,
    required List<int> answers,
    required List<Question> questions,
  }) async {
    try {
      await repository.saveQuizResult(
        topic,
        quizType,
        score,
        totalQuestions,
        answers,
        questions,
      );
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }
}
