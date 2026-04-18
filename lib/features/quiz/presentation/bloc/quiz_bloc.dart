import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:typed_data';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/question.dart';
import '../../domain/usecases/generate_quiz.dart';

part 'quiz_event.dart';
part 'quiz_state.dart';

class QuizBloc extends Bloc<QuizEvent, QuizState> {
  QuizBloc({
    required this.generateQuizUseCase,
    required this.saveQuizResultUseCase,
  }) : super(const QuizInitial()) {
    on<LoadQuiz>(_onLoadQuiz);
    on<SelectAnswer>(_onSelectAnswer);
    on<NextQuestion>(_onNextQuestion);
    on<PreviousQuestion>(_onPreviousQuestion);
    on<SubmitQuiz>(_onSubmitQuiz);
    on<ResetQuiz>(_onResetQuiz);
  }

  final GenerateQuizUseCase generateQuizUseCase;
  final SaveQuizResultUseCase saveQuizResultUseCase;

  void _onLoadQuiz(LoadQuiz event, Emitter<QuizState> emit) async {
    emit(const QuizLoading());

    if (event.preloadedQuestions != null) {
      final questions = event.preloadedQuestions!;
      emit(
        QuizLoaded(
          questions: questions,
          currentQuestionIndex: 0,
          selectedAnswers: List.filled(questions.length, -1),
          score: 0,
          difficulty: event.difficulty,
          questionCount: questions.length,
          enableTimer: event.enableTimer,
          questionDuration: event.enableTimer
              ? AppConstants.defaultQuestionDurationSeconds
              : 0,
          quizType: event.quizType,
          isUsingFallbackQuestions: false,
        ),
      );
      return;
    }

    final result = await generateQuizUseCase(
      event.topic,
      difficulty: event.difficulty,
      questionCount: event.questionCount,
      quizType: event.quizType,
      imageBytes: event.imageBytes,
      imageMimeType: event.imageMimeType,
      documentText: event.documentText,
    );

    result.fold(
      (failure) => emit(QuizError(failure.message)),
      (quizResult) => emit(
        QuizLoaded(
          questions: quizResult.questions,
          currentQuestionIndex: 0,
          selectedAnswers: List.filled(quizResult.questions.length, -1),
          score: 0,
          difficulty: event.difficulty,
          questionCount: event.questionCount,
          enableTimer: event.enableTimer,
          questionDuration: event.enableTimer
              ? AppConstants.defaultQuestionDurationSeconds
              : 0,
          quizType: event.quizType,
          isUsingFallbackQuestions: quizResult.isUsingFallback,
        ),
      ),
    );
  }

  void _onSelectAnswer(SelectAnswer event, Emitter<QuizState> emit) {
    if (state is QuizLoaded) {
      final currentState = state as QuizLoaded;
      final updatedAnswers = List<int>.from(currentState.selectedAnswers);
      updatedAnswers[event.questionIndex] = event.selectedOption;

      emit(currentState.copyWith(selectedAnswers: updatedAnswers));
    }
  }

  void _onNextQuestion(NextQuestion event, Emitter<QuizState> emit) {
    if (state is QuizLoaded) {
      final currentState = state as QuizLoaded;
      if (currentState.currentQuestionIndex <
          currentState.questions.length - 1) {
        emit(
          currentState.copyWith(
            currentQuestionIndex: currentState.currentQuestionIndex + 1,
          ),
        );
      }
    }
  }

  void _onPreviousQuestion(PreviousQuestion event, Emitter<QuizState> emit) {
    if (state is QuizLoaded) {
      final currentState = state as QuizLoaded;
      if (currentState.currentQuestionIndex > 0) {
        emit(
          currentState.copyWith(
            currentQuestionIndex: currentState.currentQuestionIndex - 1,
          ),
        );
      }
    }
  }

  void _onSubmitQuiz(SubmitQuiz event, Emitter<QuizState> emit) async {
    if (state is QuizLoaded) {
      final currentState = state as QuizLoaded;

      // Calculate score
      int score = 0;
      for (int i = 0; i < currentState.questions.length; i++) {
        if (currentState.selectedAnswers[i] ==
            currentState.questions[i].correctAnswer) {
          score++;
        }
      }

      emit(
        QuizCompleted(
          questions: currentState.questions,
          selectedAnswers: currentState.selectedAnswers,
          score: score,
          topic: event.topic,
        ),
      );

      // Save result
      await saveQuizResultUseCase(
        topic: event.topic,
        quizType: currentState.quizType,
        score: score,
        totalQuestions: currentState.questions.length,
        answers: currentState.selectedAnswers,
        questions: currentState.questions,
      );
    }
  }

  void _onResetQuiz(ResetQuiz event, Emitter<QuizState> emit) {
    emit(const QuizInitial());
  }
}
