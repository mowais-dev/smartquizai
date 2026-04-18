part of 'quiz_bloc.dart';

abstract class QuizEvent extends Equatable {
  const QuizEvent();

  @override
  List<Object?> get props => [];
}

class LoadQuiz extends QuizEvent {
  const LoadQuiz(
    this.topic, {
    this.difficulty = 'easy',
    this.questionCount = 10,
    this.enableTimer = false,
    this.quizType = 'text',
    this.imageBytes,
    this.imageMimeType,
    this.documentText,
    this.preloadedQuestions,
  });

  final String topic;
  final String difficulty;
  final int questionCount;
  final bool enableTimer;
  final String quizType;
  final Uint8List? imageBytes;
  final String? imageMimeType;
  final String? documentText;
  final List<Question>? preloadedQuestions;

  @override
  List<Object?> get props => [
    topic,
    difficulty,
    questionCount,
    enableTimer,
    quizType,
    imageBytes,
    imageMimeType,
    documentText,
    preloadedQuestions,
  ];
}

class SelectAnswer extends QuizEvent {
  const SelectAnswer(this.questionIndex, this.selectedOption);

  final int questionIndex;
  final int selectedOption;

  @override
  List<Object?> get props => [questionIndex, selectedOption];
}

class NextQuestion extends QuizEvent {
  const NextQuestion();
}

class PreviousQuestion extends QuizEvent {
  const PreviousQuestion();
}

class SubmitQuiz extends QuizEvent {
  const SubmitQuiz(this.topic);

  final String topic;

  @override
  List<Object?> get props => [topic];
}

class ResetQuiz extends QuizEvent {
  const ResetQuiz();
}
