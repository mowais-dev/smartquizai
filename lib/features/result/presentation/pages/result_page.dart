import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;

import 'package:smartquizai/core/theme/app_gradients.dart';
import 'package:smartquizai/core/theme/app_palette.dart';
import 'package:smartquizai/shared/widgets/app_button.dart';
import 'package:smartquizai/shared/widgets/gradient_background.dart';
import 'package:smartquizai/shared/widgets/glass_container.dart';
import 'package:smartquizai/shared/widgets/gradient_circular_progress.dart';

class ResultPage extends StatelessWidget {
  const ResultPage({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.topic,
  });

  final int score;
  final int totalQuestions;
  final String topic;

  int get percentage => ((score / totalQuestions) * 100).round();
  bool get isPassed => percentage >= 60;

  String get _aiFeedback {
    if (percentage >= 90) {
      return 'Excellent precision. Try increasing difficulty or adding a timer for a stronger challenge.';
    }
    if (percentage >= 75) {
      return 'Great progress. Review missed concepts, then retry with a higher difficulty to reinforce learning.';
    }
    if (percentage >= 60) {
      return 'Good effort. Focus on the questions you missed and retake the quiz to lock in the basics.';
    }
    return 'Keep going. Start with easier difficulty, slow down, and aim for accuracy over speed.';
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        context.go('/home');
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quiz Results'),
          automaticallyImplyLeading: false,
        ),
        extendBodyBehindAppBar: true,
        backgroundColor: AppPalette.background,
        body: GradientBackground(
          gradient: AppGradients.indigoToCyan,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
              child: Column(
                children: [
                  const SizedBox(height: 18),
                  GlassContainer(
                    borderRadius: 20,
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                    child: Column(
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: percentage / 100),
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) {
                            return SizedBox(
                              height: 240,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final base = math.min(
                                    constraints.maxWidth,
                                    constraints.maxHeight,
                                  );
                                  final circleSize = (base * 0.92).clamp(
                                    200.0,
                                    240.0,
                                  );
                                  final percentFont = circleSize * 0.22;
                                  final scoreFont = circleSize * 0.085;

                                  return Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      GradientCircularProgress(
                                        value: value,
                                        size: circleSize,
                                        strokeWidth: 12,
                                      ),
                                      ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxWidth: circleSize * 0.78,
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                '$percentage%',
                                                maxLines: 1,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .headlineMedium
                                                    ?.copyWith(
                                                      fontSize: percentFont,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      letterSpacing: -0.4,
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                '$score / $totalQuestions',
                                                maxLines: 1,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      fontSize: scoreFont,
                                                      color: AppPalette
                                                          .textSecondary,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isPassed ? 'Passed' : 'Not passed',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: isPassed
                                    ? AppPalette.success
                                    : AppPalette.error,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Topic: $topic',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppPalette.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        GlassContainer(
                          borderRadius: 18,
                          blurSigma: 14,
                          tint: Colors.white.withOpacity(0.05),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI feedback',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _aiFeedback,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: AppPalette.textSecondary,
                                      height: 1.35,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  AppButton(
                    onPressed: () => context.go('/home'),
                    text: 'Take Another Quiz',
                    icon: Icons.refresh,
                  ),
                  const SizedBox(height: 14),
                  GlassContainer(
                    borderRadius: 18,
                    blurSigma: 14,
                    padding: EdgeInsets.zero,
                    onTap: () => context.go('/history'),
                    child: ListTile(
                      leading: const Icon(
                        Icons.history,
                        color: AppPalette.textPrimary,
                      ),
                      title: Text(
                        'View History',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        'Review question-by-question details.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppPalette.textSecondary,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
