import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smartquizai/features/group/data/group_test_service.dart';
import 'package:smartquizai/core/services/service_locator.dart';
import 'package:smartquizai/core/theme/app_gradients.dart';
import 'package:smartquizai/core/theme/app_palette.dart';
import 'package:smartquizai/shared/widgets/app_button.dart';
import 'package:smartquizai/shared/widgets/gradient_background.dart';
import 'package:smartquizai/shared/widgets/glass_container.dart';

class GroupResultPage extends StatefulWidget {
  const GroupResultPage({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.topic,
    required this.testId,
    required this.studentName,
    required this.studentRoll,
    this.studentSection,
    required this.quizType,
    this.answers,
    this.questions,
  });

  final int score;
  final int totalQuestions;
  final String topic;
  final String testId;
  final String studentName;
  final String studentRoll;
  final String? studentSection;
  final String quizType;
  final List<int>? answers;
  final List<dynamic>? questions;

  @override
  State<GroupResultPage> createState() => _GroupResultPageState();
}

class _GroupResultPageState extends State<GroupResultPage> {
  bool _saving = true;
  bool _saved = false;
  String? _error;

  GroupTestService get _service => sl<GroupTestService>();

  int get percentage => ((widget.score / widget.totalQuestions) * 100).round();

  @override
  void initState() {
    super.initState();
    _saveResult();
  }

  Future<void> _saveResult() async {
    try {
      await _service.saveStudentResult(
        testId: widget.testId,
        studentName: widget.studentName,
        studentRoll: widget.studentRoll,
        studentSection: widget.studentSection,
        score: widget.score,
        totalQuestions: widget.totalQuestions,
        topicTitle: widget.topic,
        quizType: widget.quizType,
        answers: widget.answers,
        questions: widget.questions
            ?.map(
              (item) => item is Map<String, dynamic>
                  ? item
                  : Map<String, dynamic>.from(item as Map),
            )
            .toList(),
      );
      if (mounted) {
        setState(() {
          _saved = true;
          _saving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        context.go('/home');
        return false;
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Test Result')),
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
                        Text(
                          'Welcome ${widget.studentName}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.studentSection?.isNotEmpty == true
                              ? 'Section: ${widget.studentSection}'
                              : 'Section not provided',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppPalette.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Score: ${widget.score} / ${widget.totalQuestions}',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$percentage%',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppPalette.primaryA,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.topic,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppPalette.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        if (_saving)
                          const CircularProgressIndicator()
                        else if (_error != null)
                          Text(
                            'Could not save result. $_error',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppPalette.error),
                          )
                        else if (_saved)
                          Text(
                            'Result saved successfully.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppPalette.success),
                          ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  AppButton(
                    onPressed: () => context.go('/home'),
                    text: 'Return Home',
                    icon: Icons.home,
                  ),
                  const SizedBox(height: 14),
                  AppButton(
                    onPressed: () => context.go(
                      '/group-test/results?testId=${Uri.encodeQueryComponent(widget.testId)}',
                    ),
                    text: 'View All Student Results',
                    icon: Icons.people,
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
