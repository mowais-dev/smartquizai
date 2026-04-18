import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smartquizai/features/group/data/group_test_service.dart';
import 'package:smartquizai/core/services/service_locator.dart';
import 'package:smartquizai/core/theme/app_gradients.dart';
import 'package:smartquizai/core/theme/app_palette.dart';
import 'package:smartquizai/shared/widgets/gradient_background.dart';
import 'package:smartquizai/shared/widgets/glass_container.dart';

class GroupTestResultsPage extends StatefulWidget {
  const GroupTestResultsPage({super.key, required this.testId});

  final String testId;

  @override
  State<GroupTestResultsPage> createState() => _GroupTestResultsPageState();
}

class _GroupTestResultsPageState extends State<GroupTestResultsPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _results = [];
  String? _error;

  GroupTestService get _service => sl<GroupTestService>();

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    try {
      final results = await _service.fetchStudentResults(widget.testId);
      results.sort(
        (a, b) =>
            b['submittedAt']?.toString().compareTo(
              a['submittedAt']?.toString() ?? '',
            ) ??
            0,
      );
      setState(() {
        _results = results;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildResultTile(Map<String, dynamic> result) {
    final score = result['score']?.toString() ?? '0';
    final total = result['totalQuestions']?.toString() ?? '0';
    final percent = result['percentage']?.toString() ?? '0';
    final submittedAt = result['submittedAt']?.toString() ?? '';
    return GlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      onTap: () => _showResultDetails(result),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result['studentName'] ?? 'Unknown student',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Roll: ${result['studentRoll'] ?? ''}${result['studentSection']?.toString().isNotEmpty == true ? ' • Section: ${result['studentSection']}' : ''}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppPalette.textSecondary),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Chip(label: Text('Score $score / $total')),
              const SizedBox(width: 8),
              Chip(label: Text('$percent%')),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Submitted: $submittedAt',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppPalette.textSecondary),
          ),
        ],
      ),
    );
  }

  void _showResultDetails(Map<String, dynamic> result) {
    final studentName = result['studentName'] ?? 'Unknown student';
    final studentRoll = result['studentRoll'] ?? '';
    final studentSection = result['studentSection']?.toString();
    final score = result['score']?.toString() ?? '0';
    final total = result['totalQuestions']?.toString() ?? '0';
    final percent = result['percentage']?.toString() ?? '0';
    final topicTitle = result['topicTitle']?.toString() ?? 'Group Test';
    final quizType = result['quizType']?.toString() ?? 'text';
    final submittedAt = result['submittedAt']?.toString() ?? '';

    final rawAnswers = result['answers'];
    final answers = <int>[];
    if (rawAnswers is List) {
      for (final answer in rawAnswers) {
        if (answer is int) {
          answers.add(answer);
        } else if (answer is String) {
          answers.add(int.tryParse(answer) ?? -1);
        }
      }
    }

    final rawQuestions = result['questions'];
    final questions = <Map<String, dynamic>>[];
    if (rawQuestions is List) {
      for (final item in rawQuestions) {
        if (item is Map<String, dynamic>) {
          questions.add(item);
        } else if (item is Map) {
          questions.add(Map<String, dynamic>.from(item));
        }
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  studentName,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  studentSection?.isNotEmpty == true
                      ? 'Roll: $studentRoll • Section: $studentSection'
                      : 'Roll: $studentRoll',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppPalette.textSecondary,
                  ),
                ),
                const SizedBox(height: 18),
                _buildDetailRow('Topic', topicTitle),
                _buildDetailRow('Quiz type', quizType),
                _buildDetailRow('Score', '$score / $total'),
                _buildDetailRow('Percentage', '$percent%'),
                _buildDetailRow('Submitted', submittedAt),
                if (questions.isNotEmpty && answers.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text(
                    'Answers',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...questions.asMap().entries.map((entry) {
                    final questionIndex = entry.key;
                    final question = entry.value;
                    final questionText = question['question']?.toString() ?? '';
                    final options =
                        (question['options'] as List<dynamic>?)
                            ?.map((opt) => opt.toString())
                            .toList() ??
                        [];
                    final correctAnswer =
                        int.tryParse(
                          question['correctAnswer']?.toString() ?? '',
                        ) ??
                        -1;
                    final selectedAnswer = questionIndex < answers.length
                        ? answers[questionIndex]
                        : -1;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Q${questionIndex + 1}: $questionText',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          ...options.asMap().entries.map((optionEntry) {
                            final optionIndex = optionEntry.key;
                            final optionText = optionEntry.value;
                            final isSelected = optionIndex == selectedAnswer;
                            final isCorrect = optionIndex == correctAnswer;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    isCorrect
                                        ? Icons.check_circle_outline
                                        : isSelected
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_off,
                                    size: 18,
                                    color: isCorrect
                                        ? Colors.greenAccent
                                        : isSelected
                                        ? Colors.amberAccent
                                        : Colors.white70,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      optionText,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: isCorrect
                                                ? Colors.greenAccent
                                                : isSelected
                                                ? Colors.amberAccent
                                                : AppPalette.textSecondary,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          if (selectedAnswer < 0)
                            Text(
                              'Not answered',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppPalette.textSecondary),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'Not available',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppPalette.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        context.go('/home');
        return false;
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Student Results')),
        extendBodyBehindAppBar: true,
        backgroundColor: AppPalette.background,
        body: GradientBackground(
          gradient: AppGradients.deepPurpleToBlue,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: Text(
                        'Unable to load results. $_error',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    )
                  : _results.isEmpty
                  ? Center(
                      child: Text(
                        'No student results submitted yet for this test.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppPalette.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.separated(
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) =>
                          _buildResultTile(_results[index]),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
