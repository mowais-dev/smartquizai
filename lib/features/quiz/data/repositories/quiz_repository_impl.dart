import 'package:dartz/dartz.dart';
import 'dart:typed_data';

import '../../../../core/error/failure.dart';
import '../../domain/entities/question.dart';
import '../../domain/repositories/quiz_repository.dart';
import '../datasources/quiz_firebase_data_source.dart';
import '../datasources/quiz_local_data_source.dart';
import '../datasources/quiz_remote_data_source.dart';

class QuizRepositoryImpl implements QuizRepository {
  const QuizRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.firebaseDataSource,
  });

  final QuizRemoteDataSource remoteDataSource;
  final QuizLocalDataSource localDataSource;
  final QuizFirebaseDataSource firebaseDataSource;

  @override
  Future<Either<Failure, QuizGenerationResult>> generateQuiz(
    String topic, {
    required String difficulty,
    required int questionCount,
    required String quizType,
    Uint8List? imageBytes,
    String? imageMimeType,
    String? documentText,
  }) async {
    try {
      final questionModels = await remoteDataSource.generateQuiz(
        topic,
        difficulty: difficulty,
        questionCount: questionCount,
        quizType: quizType,
        imageBytes: imageBytes,
        imageMimeType: imageMimeType,
        documentText: documentText,
      );
      final isUsingFallback = questionModels.any(
        (q) =>
            q.question.contains('sample question') ||
            q.question.contains('Sample question') ||
            q.question.contains('Fallback question') ||
            q.question.contains('fallback question'),
      );

      return Right(
        QuizGenerationResult(
          questions: questionModels.map((model) => model as Question).toList(),
          isUsingFallback: isUsingFallback,
        ),
      );
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveQuizResult(
    String topic,
    String quizType,
    int score,
    int totalQuestions,
    List<int> answers,
    List<Question> questions,
  ) async {
    try {
      final firebaseId = await firebaseDataSource.saveQuizResult(
        topic: topic,
        quizType: quizType,
        score: score,
        totalQuestions: totalQuestions,
        date: DateTime.now(),
        answers: answers,
        questions: questions,
      );

      await localDataSource.saveQuizResult(
        topic: topic,
        quizType: quizType,
        score: score,
        totalQuestions: totalQuestions,
        firebaseId: firebaseId,
      );

      return const Right(null);
    } catch (e) {
      try {
        await localDataSource.saveQuizResult(
          topic: topic,
          quizType: quizType,
          score: score,
          totalQuestions: totalQuestions,
        );
      } catch (_) {
        // ignore local fallback failure
      }
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getQuizResultDetail(
    String id,
  ) async {
    try {
      final result = await firebaseDataSource.getQuizResultById(id);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
