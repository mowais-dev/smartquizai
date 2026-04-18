import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:smartquizai/core/theme/app_palette.dart';
import 'dart:typed_data';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/service_locator.dart';
import '../../../quiz/data/models/question_model.dart';
import '../../../quiz/domain/entities/question.dart';
import '../../../quiz/presentation/bloc/quiz_bloc.dart';
import '../../../quiz/presentation/widgets/quiz_content.dart';
import 'package:smartquizai/shared/widgets/loader.dart';
import 'package:smartquizai/shared/widgets/gradient_background.dart';
import 'package:smartquizai/core/theme/app_gradients.dart';

class QuizPage extends StatelessWidget {
  const QuizPage({
    super.key,
    required this.topic,
    required this.difficulty,
    required this.questionCount,
    required this.timerEnabled,
    required this.quizType,
    this.groupTestId,
    this.studentName,
    this.studentRoll,
    this.studentSection,
    this.imageBytes,
    this.imageMimeType,
    this.documentText,
    this.preloadedQuestions,
  });

  final String topic;
  final String difficulty;
  final int questionCount;
  final bool timerEnabled;
  final String quizType;
  final String? groupTestId;
  final String? studentName;
  final String? studentRoll;
  final String? studentSection;
  final Uint8List? imageBytes;
  final String? imageMimeType;
  final String? documentText;
  final List<dynamic>? preloadedQuestions;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<QuizBloc>()
        ..add(
          LoadQuiz(
            topic,
            difficulty: difficulty,
            questionCount: questionCount,
            enableTimer: timerEnabled,
            quizType: quizType,
            imageBytes: imageBytes,
            imageMimeType: imageMimeType,
            documentText: documentText,
            preloadedQuestions: preloadedQuestions?.map<Question>((item) {
              if (item is Question) return item;
              if (item is QuestionModel) return item;
              if (item is Map<String, dynamic>) {
                return QuestionModel.fromJson(item);
              }
              if (item is Map) {
                return QuestionModel.fromJson(Map<String, dynamic>.from(item));
              }
              throw StateError(
                'Unsupported preloaded question type: ${item.runtimeType}',
              );
            }).toList(),
          ),
        ),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Quiz: $topic'),
          leading: IconButton(
            onPressed: () => context.go('/home'),
            icon: const Icon(Icons.close),
          ),
        ),
        extendBodyBehindAppBar: true,
        backgroundColor: AppPalette.background,
        body: GradientBackground(
          gradient: AppGradients.deepPurpleToBlue,
          addGlows: false,
          child: SafeArea(
            child: BlocBuilder<QuizBloc, QuizState>(
              builder: (context, state) {
                if (state is QuizLoading) {
                  return const FullScreenLoader(
                    message:
                        'Generating your quiz...\nThis may take a few seconds if rate limited',
                  );
                }
                if (state is QuizError) {
                  if (state.message.isNotEmpty) {
                    debugPrint(state.message);
                  }
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: AppPalette.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to generate quiz',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.message,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Colors.white.withAlpha(
                                    (0.85 * 255).round(),
                                  ),
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => context.read<QuizBloc>().add(
                              LoadQuiz(
                                topic,
                                difficulty: difficulty,
                                questionCount: questionCount,
                                enableTimer: timerEnabled,
                                quizType: quizType,
                              ),
                            ),
                            child: const Text('Try Again'),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => context.go('/home'),
                            child: const Text('Go Back'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (state is QuizLoaded) {
                  if (state.isUsingFallbackQuestions) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'AI quiz generation encountered an issue. Using sample questions instead.',
                          ),
                          duration: const Duration(seconds: 5),
                          backgroundColor: AppPalette.surface.withAlpha(
                            (0.95 * 255).round(),
                          ),
                        ),
                      );
                    });
                  }
                  return QuizContent(
                    state: state,
                    topic: topic,
                    questionDuration: timerEnabled
                        ? AppConstants.defaultQuestionDurationSeconds
                        : 0,
                    isTimerEnabled: timerEnabled,
                  );
                }

                if (state is QuizCompleted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (groupTestId != null &&
                        studentName != null &&
                        studentRoll != null) {
                      final uri = Uri(
                        path: '/group-result',
                        queryParameters: {
                          'score': state.score.toString(),
                          'total': state.totalQuestions.toString(),
                          'topic': topic,
                          'testId': groupTestId,
                          'studentName': studentName,
                          'studentRoll': studentRoll,
                          if (studentSection != null)
                            'studentSection': studentSection,
                          'quizType': quizType,
                        },
                      );
                      context.go(
                        uri.toString(),
                        extra: {
                          'answers': state.selectedAnswers,
                          'questions': state.questions.map((question) {
                            return {
                              'id': question.id,
                              'question': question.question,
                              'options': question.options,
                              'correctAnswer': question.correctAnswer,
                              'explanation': question.explanation ?? '',
                            };
                          }).toList(),
                        },
                      );
                      return;
                    }

                    context.go(
                      '/result?score=${state.score}&total=${state.totalQuestions}&topic=$topic',
                    );
                  });
                  return const FullScreenLoader(
                    message: 'Calculating results...',
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
  }
}
