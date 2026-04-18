import 'package:dartz/dartz.dart' as dartz;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smartquizai/core/error/failure.dart';
import 'package:smartquizai/core/services/service_locator.dart';
import 'package:smartquizai/core/theme/app_gradients.dart';
import 'package:smartquizai/core/theme/app_palette.dart';
import 'package:smartquizai/core/utils/app_utils.dart';
import 'package:smartquizai/features/quiz/domain/repositories/quiz_repository.dart';
import 'package:smartquizai/shared/widgets/gradient_background.dart';
import 'package:smartquizai/shared/widgets/glass_container.dart';

class HistoryDetailPage extends StatefulWidget {
  const HistoryDetailPage({super.key, required this.historyItem});

  final Map<String, dynamic> historyItem;

  @override
  State<HistoryDetailPage> createState() => _HistoryDetailPageState();
}

class _HistoryDetailPageState extends State<HistoryDetailPage> {
  late final Future<dartz.Either<Failure, Map<String, dynamic>>> _detailFuture;

  @override
  void initState() {
    super.initState();
    final id = widget.historyItem['id'] as String?;
    if (id != null && id.isNotEmpty) {
      _detailFuture = sl<QuizRepository>().getQuizResultDetail(id);
    } else {
      _detailFuture = Future.value(dartz.Right(widget.historyItem));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('History Details'),
      ),
      extendBodyBehindAppBar: true,
      backgroundColor: AppPalette.background,
      body: GradientBackground(
        gradient: AppGradients.deepPurpleToBlue,
        child: SafeArea(
          child: FutureBuilder<dartz.Either<Failure, Map<String, dynamic>>>(
            future: _detailFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(
                  child: CircularProgressIndicator(color: AppPalette.primaryB),
                );
              }

              if (!snapshot.hasData) {
                return _buildContent(
                  widget.historyItem,
                  message: 'Unable to load details.',
                );
              }

              return snapshot.data!.fold(
                (failure) =>
                    _buildContent(widget.historyItem, message: failure.message),
                (remoteItem) => _buildContent(
                  remoteItem,
                  message: 'Loaded from Firebase Realtime Database',
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic> historyItem, {String? message}) {
    final date = DateTime.tryParse(historyItem['date'] ?? '') ?? DateTime.now();
    final score = historyItem['score'] as int? ?? 0;
    final totalQuestions = historyItem['totalQuestions'] as int? ?? 0;
    final percentage = historyItem['percentage'] as int? ?? 0;
    final isPassed = percentage >= 60;
    final answers = <int>[];
    final rawAnswers = historyItem['answers'];
    if (rawAnswers is List) {
      for (final answer in rawAnswers) {
        if (answer is int) {
          answers.add(answer);
        } else if (answer is String) {
          final parsed = int.tryParse(answer);
          if (parsed != null) answers.add(parsed);
        }
      }
    }

    final questions = historyItem['questions'] is List
        ? (historyItem['questions'] as List).whereType<dynamic>().toList()
        : <dynamic>[];

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlassContainer(
              borderRadius: 20,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    historyItem['topic'] ?? 'Unknown Topic',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _MetaChip(
                        icon: Icons.insights,
                        label: '$percentage%',
                        gradient: AppGradients.primary,
                      ),
                      _MetaChip(
                        icon: isPassed ? Icons.check_circle : Icons.cancel,
                        label: isPassed ? 'Passed' : 'Failed',
                        color: isPassed ? AppPalette.success : AppPalette.error,
                      ),
                      _MetaChip(
                        icon: Icons.list_alt,
                        label: '$score / $totalQuestions',
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Taken on ${AppUtils.formatDateTime(date)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppPalette.textSecondary,
                        ),
                  ),
                  if (message != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      message,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppPalette.textSecondary,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Question details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            ...questions.asMap().entries.map((entry) {
              final index = entry.key;
              final rawQuestion = entry.value;
              final question = rawQuestion is Map
                  ? rawQuestion.map(
                      (key, value) => MapEntry(key.toString(), value),
                    )
                  : <String, dynamic>{};
              final questionText =
                  question['question'] as String? ?? 'Unknown question';
              final options =
                  (question['options'] is List
                          ? (question['options'] as List).cast<dynamic>()
                          : <dynamic>[])
                      .map((e) => e.toString())
                      .toList();
              final correctAnswerIndex = question['correctAnswer'] is int
                  ? question['correctAnswer'] as int
                  : int.tryParse(question['correctAnswer']?.toString() ?? '') ??
                        0;
              final explanation = question['explanation']?.toString();
              final userAnswerIndex = answers.length > index
                  ? answers[index]
                  : -1;
              final isCorrect = userAnswerIndex == correctAnswerIndex;

              return GlassContainer(
                margin: const EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.zero,
                borderRadius: 18,
                child: Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                    splashColor: Colors.white.withOpacity(0.06),
                    highlightColor: Colors.white.withOpacity(0.04),
                  ),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    title: Text(
                      'Question ${index + 1}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    subtitle: Text(
                      isCorrect ? 'Correct' : 'Incorrect',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                isCorrect ? AppPalette.success : AppPalette.error,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    trailing: Icon(
                      isCorrect ? Icons.check_circle : Icons.cancel,
                      color: isCorrect ? AppPalette.success : AppPalette.error,
                    ),
                    children: [
                      Text(
                        questionText,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              height: 1.35,
                            ),
                      ),
                      const SizedBox(height: 12),
                      ...options.asMap().entries.map((optionEntry) {
                        final optionIndex = optionEntry.key;
                        final optionText = optionEntry.value;
                        final isUserSelected = optionIndex == userAnswerIndex;
                        final isCorrectOption = optionIndex == correctAnswerIndex;

                        final tint = isCorrectOption
                            ? AppPalette.success.withOpacity(0.14)
                            : isUserSelected && !isCorrect
                                ? AppPalette.error.withOpacity(0.14)
                                : Colors.white.withOpacity(0.04);

                        final border = isCorrectOption
                            ? AppPalette.success.withOpacity(0.75)
                            : isUserSelected && !isCorrect
                                ? AppPalette.error.withOpacity(0.75)
                                : Colors.white.withOpacity(0.10);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: tint,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: border, width: 1),
                          ),
                          child: Row(
                            children: [
                              Text(
                                '${String.fromCharCode(65 + optionIndex)}.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: AppPalette.textPrimary,
                                    ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  optionText,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              if (isCorrectOption) ...[
                                const SizedBox(width: 10),
                                const Icon(
                                  Icons.check_circle,
                                  color: AppPalette.success,
                                  size: 18,
                                ),
                              ] else if (isUserSelected && !isCorrect) ...[
                                const SizedBox(width: 10),
                                const Icon(
                                  Icons.cancel,
                                  color: AppPalette.error,
                                  size: 18,
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                      if (explanation != null && explanation.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        GlassContainer(
                          borderRadius: 16,
                          blurSigma: 14,
                          tint: Colors.white.withOpacity(0.05),
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Explanation',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                explanation,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppPalette.textSecondary,
                                      height: 1.35,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    this.color,
    this.gradient,
  });

  final IconData icon;
  final String label;
  final Color? color;
  final LinearGradient? gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: gradient,
        color: gradient == null ? Colors.white.withOpacity(0.06) : null,
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color ?? AppPalette.textPrimary),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color ?? AppPalette.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}
