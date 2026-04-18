import '../../../../core/services/storage_service.dart';

abstract class QuizLocalDataSource {
  Future<void> saveQuizResult({
    required String topic,
    required String quizType,
    required int score,
    required int totalQuestions,
    String? firebaseId,
  });
}

class QuizLocalDataSourceImpl implements QuizLocalDataSource {
  const QuizLocalDataSourceImpl();

  @override
  Future<void> saveQuizResult({
    required String topic,
    required String quizType,
    required int score,
    required int totalQuestions,
    String? firebaseId,
  }) async {
    await StorageService.saveQuizResult(
      topic: topic,
      quizType: quizType,
      score: score,
      totalQuestions: totalQuestions,
      date: DateTime.now(),
      firebaseId: firebaseId,
    );
  }
}
