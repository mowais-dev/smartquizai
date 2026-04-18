part of 'quiz_bloc.dart';

abstract class QuizState extends Equatable {
  const QuizState();

  @override
  List<Object?> get props => [];
}

class QuizInitial extends QuizState {
  const QuizInitial();
}

class QuizLoading extends QuizState {
  const QuizLoading();
}

class QuizLoaded extends QuizState {
  const QuizLoaded({
    required this.questions,
    required this.currentQuestionIndex,
    required this.selectedAnswers,
    required this.score,
    this.difficulty = 'easy',
    this.questionCount = 10,
    this.enableTimer = false,
    this.questionDuration = 0,
    this.quizType = 'text',
    this.isUsingFallbackQuestions = false,
  });

  final List<Question> questions;
  final int currentQuestionIndex;
  final List<int> selectedAnswers;
  final int score;
  final String difficulty;
  final int questionCount;
  final bool enableTimer;
  final int questionDuration;
  final String quizType;
  final bool isUsingFallbackQuestions;

  Question get currentQuestion => questions[currentQuestionIndex];
  int get totalQuestions => questions.length;
  int get selectedAnswer => selectedAnswers[currentQuestionIndex];
  bool get isLastQuestion => currentQuestionIndex == questions.length - 1;
  bool get isFirstQuestion => currentQuestionIndex == 0;

  double get progress => (currentQuestionIndex + 1) / questions.length;

  QuizLoaded copyWith({
    List<Question>? questions,
    int? currentQuestionIndex,
    List<int>? selectedAnswers,
    int? score,
    String? difficulty,
    int? questionCount,
    bool? enableTimer,
    int? questionDuration,
    String? quizType,
    bool? isUsingFallbackQuestions,
  }) {
    return QuizLoaded(
      questions: questions ?? this.questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
      score: score ?? this.score,
      difficulty: difficulty ?? this.difficulty,
      questionCount: questionCount ?? this.questionCount,
      enableTimer: enableTimer ?? this.enableTimer,
      questionDuration: questionDuration ?? this.questionDuration,
      quizType: quizType ?? this.quizType,
      isUsingFallbackQuestions:
          isUsingFallbackQuestions ?? this.isUsingFallbackQuestions,
    );
  }

  @override
  List<Object?> get props => [
        questions,
        currentQuestionIndex,
        selectedAnswers,
        score,
        difficulty,
        questionCount,
        enableTimer,
        questionDuration,
        quizType,
        isUsingFallbackQuestions,
      ];
}

class QuizCompleted extends QuizState {
  const QuizCompleted({
    required this.questions,
    required this.selectedAnswers,
    required this.score,
    required this.topic,
  });

  final List<Question> questions;
  final List<int> selectedAnswers;
  final int score;
  final String topic;

  int get totalQuestions => questions.length;
  int get percentage => ((score / totalQuestions) * 100).round();
  bool get isPassed => percentage >= 60;

  @override
  List<Object?> get props => [questions, selectedAnswers, score, topic];
}

class QuizError extends QuizState {
  const QuizError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
