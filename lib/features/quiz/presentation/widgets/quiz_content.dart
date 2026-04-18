import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/quiz_option_tile.dart';
import '../../../../shared/widgets/gradient_progress_bar.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../bloc/quiz_bloc.dart';

class QuizContent extends StatefulWidget {
  const QuizContent({
    super.key,
    required this.state,
    required this.topic,
    required this.isTimerEnabled,
    required this.questionDuration,
  });

  final QuizLoaded state;
  final String topic;
  final bool isTimerEnabled;
  final int questionDuration;

  @override
  State<QuizContent> createState() => _QuizContentState();
}

class _QuizContentState extends State<QuizContent> {
  Timer? _timer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _resetTimer();
  }

  @override
  void didUpdateWidget(covariant QuizContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.currentQuestionIndex !=
            oldWidget.state.currentQuestionIndex ||
        widget.isTimerEnabled != oldWidget.isTimerEnabled ||
        widget.questionDuration != oldWidget.questionDuration) {
      _resetTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _resetTimer() {
    _timer?.cancel();
    if (!widget.isTimerEnabled || widget.questionDuration <= 0) {
      setState(() => _remainingSeconds = 0);
      return;
    }

    setState(() => _remainingSeconds = widget.questionDuration);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        _onTimeExpired();
        return;
      }
      if (mounted) {
        setState(() => _remainingSeconds -= 1);
      }
    });
  }

  void _onTimeExpired() {
    final quizBloc = context.read<QuizBloc>();
    if (widget.state.isLastQuestion) {
      _showSubmitDialog(context, quizBloc);
    } else {
      quizBloc.add(NextQuestion());
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizBloc = context.read<QuizBloc>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      child: Column(
        children: [
          GradientProgressBar(value: widget.state.progress),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${widget.state.currentQuestionIndex + 1} of ${widget.state.totalQuestions}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppPalette.textSecondary,
                    ),
              ),
              if (widget.isTimerEnabled)
                Row(
                  children: [
                    const Icon(Icons.timer, size: 18, color: AppPalette.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      '$_remainingSeconds s',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppPalette.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppPalette.surface.withOpacity(0.78),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.state.currentQuestion.question,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                            letterSpacing: -0.2,
                          ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 12),
                        itemCount: widget.state.currentQuestion.options.length,
                        itemBuilder: (context, index) {
                          return QuizOptionTile(
                            option: widget.state.currentQuestion.options[index],
                            isSelected: widget.state.selectedAnswer == index,
                            isCorrect:
                                widget.state.currentQuestion.correctAnswer == index,
                            isAnswered: false,
                            onTap: () => quizBloc.add(
                              SelectAnswer(
                                widget.state.currentQuestionIndex,
                                index,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (!widget.state.isFirstQuestion)
                SizedBox(
                  width: 80,
                  child: AppButton(
                    onPressed: () => quizBloc.add(PreviousQuestion()),
                    text: '',
                    icon: Icons.arrow_back,
                    isDisabled: widget.state.isFirstQuestion,
                  ),
                ),
              if (!widget.state.isFirstQuestion) const SizedBox(width: 16),
              Expanded(
                flex: widget.state.isFirstQuestion ? 1 : 2,
                child: AppButton(
                  onPressed: widget.state.isLastQuestion
                      ? () => _showSubmitDialog(context, quizBloc)
                      : () => quizBloc.add(NextQuestion()),
                  text: widget.state.isLastQuestion ? 'Submit Quiz' : 'Next',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSubmitDialog(BuildContext context, QuizBloc quizBloc) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (context) {
        final answered =
            widget.state.selectedAnswers.where((answer) => answer != -1).length;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: GlassContainer(
            borderRadius: 20,
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Submit quiz?',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  'You answered $answered out of ${widget.state.totalQuestions} questions. '
                  'You can still review answers later in history.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppPalette.textSecondary,
                        height: 1.35,
                      ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppPalette.textPrimary,
                          side: BorderSide(color: Colors.white.withOpacity(0.18)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          quizBloc.add(SubmitQuiz(widget.topic));
                        },
                        text: 'Submit',
                        icon: Icons.check,
                        height: 48,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
