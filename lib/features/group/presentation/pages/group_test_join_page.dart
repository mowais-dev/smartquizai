import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smartquizai/features/group/data/group_test_service.dart';
import 'package:smartquizai/core/services/service_locator.dart';
import 'package:smartquizai/core/theme/app_gradients.dart';
import 'package:smartquizai/core/theme/app_palette.dart';
import 'package:smartquizai/shared/widgets/app_button.dart';
import 'package:smartquizai/shared/widgets/app_card.dart';
import 'package:smartquizai/shared/widgets/app_text_field.dart';
import 'package:smartquizai/shared/widgets/gradient_background.dart';

class GroupTestJoinPage extends StatefulWidget {
  const GroupTestJoinPage({super.key, required this.testId});

  final String testId;

  @override
  State<GroupTestJoinPage> createState() => _GroupTestJoinPageState();
}

class _GroupTestJoinPageState extends State<GroupTestJoinPage> {
  bool _isLoading = true;
  bool _isStarting = false;
  Map<String, dynamic>? _test;
  String? _errorMessage;
  DateTime? _startAt;
  DateTime? _endAt;

  final _nameController = TextEditingController();
  final _rollController = TextEditingController();
  final _sectionController = TextEditingController();

  GroupTestService get _service => sl<GroupTestService>();

  @override
  void initState() {
    super.initState();
    _loadTest();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rollController.dispose();
    _sectionController.dispose();
    super.dispose();
  }

  Future<void> _loadTest() async {
    try {
      final test = await _service.fetchTestById(widget.testId);
      DateTime? startAt;
      DateTime? endAt;
      try {
        startAt = DateTime.parse(test['startAt']?.toString() ?? '');
      } catch (_) {
        startAt = null;
      }
      try {
        endAt = DateTime.parse(test['endAt']?.toString() ?? '');
      } catch (_) {
        endAt = null;
      }
      setState(() {
        _test = test;
        _startAt = startAt;
        _endAt = endAt;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Unable to load shared test.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool get _isWithinWindow {
    if (_startAt == null || _endAt == null) return false;
    final now = DateTime.now();
    return !now.isBefore(_startAt!) && !now.isAfter(_endAt!);
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Not set';
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _startQuiz() {
    if (_nameController.text.trim().isEmpty ||
        _rollController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name and roll number are required before starting.'),
        ),
      );
      return;
    }
    if (!_isWithinWindow) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This quiz can only be taken during the scheduled window.',
          ),
        ),
      );
      return;
    }
    if (_test == null) return;
    final topic = _test!['title']?.toString() ?? 'Group Test';
    final difficulty = _test!['difficulty']?.toString() ?? 'easy';
    final count =
        int.tryParse(_test!['questionCount']?.toString() ?? '10') ?? 10;
    final timerEnabled =
        (int.tryParse(_test!['timerSeconds']?.toString() ?? '0') ?? 0) > 0;
    final quizType = _test!['quizType']?.toString() ?? 'text';
    final questions = _test!['questions'] as List<dynamic>?;

    final uri = Uri(
      path: '/quiz',
      queryParameters: {
        'topic': topic,
        'difficulty': difficulty,
        'count': count.toString(),
        'timer': timerEnabled ? '1' : '0',
        'type': quizType,
        'groupTestId': widget.testId,
        'studentName': _nameController.text.trim(),
        'studentRoll': _rollController.text.trim(),
        if (_sectionController.text.trim().isNotEmpty)
          'studentSection': _sectionController.text.trim(),
      },
    );

    context.go(uri.toString(), extra: {'preloadedQuestions': questions});
  }

  Widget _buildTestPreview() {
    if (_test == null) return const SizedBox.shrink();
    final imageBase64 = _test!['imageBase64'] as String?;
    final mimeType = _test!['imageMimeType'] as String?;
    final documentName = _test!['documentName'] as String?;
    final documentText = _test!['documentText'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Test details',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          _test!['title']?.toString() ?? '',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          _test!['description']?.toString() ?? '',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppPalette.textSecondary,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Available from ${_formatDateTime(_startAt)} to ${_formatDateTime(_endAt)}',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppPalette.textSecondary),
        ),
        const SizedBox(height: 12),
        if (!_isWithinWindow) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppPalette.error.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _startAt == null || _endAt == null
                  ? 'This quiz schedule is incomplete.'
                  : DateTime.now().isBefore(_startAt!)
                  ? 'This quiz has not started yet.'
                  : 'This quiz has already ended.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppPalette.error),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (imageBase64 != null && mimeType != null) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            width: double.infinity,
            child: Image.memory(base64Decode(imageBase64), fit: BoxFit.cover),
          ),
        ],
        if (documentName != null) ...[
          const SizedBox(height: 16),
          Text(
            'Document: $documentName',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (documentText != null && documentText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              documentText,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppPalette.textSecondary),
            ),
          ],
        ],
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          children: [
            Chip(label: Text('Type: ${_test!['quizType'] ?? 'text'}')),
            Chip(label: Text('Count: ${_test!['questionCount'] ?? '10'}')),
            Chip(label: Text('Timer: ${_test!['timerSeconds'] ?? 0}s')),
          ],
        ),
      ],
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
        appBar: AppBar(title: const Text('Join Shared Test')),
        extendBodyBehindAppBar: true,
        backgroundColor: AppPalette.background,
        body: GradientBackground(
          gradient: AppGradients.deepPurpleToBlue,
          child: SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
                    child: Text(
                      _errorMessage!,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Shared group test',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enter your details to start the shared test.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppPalette.textSecondary,
                                height: 1.35,
                              ),
                        ),
                        const SizedBox(height: 20),
                        AppCard(
                          padding: const EdgeInsets.all(20),
                          child: _buildTestPreview(),
                        ),
                        const SizedBox(height: 20),
                        AppTextField(
                          controller: _nameController,
                          labelText: 'Name',
                          hintText: 'Student name',
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          controller: _rollController,
                          labelText: 'Roll number',
                          hintText: 'Enter roll number',
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          controller: _sectionController,
                          labelText: 'Section (optional)',
                          hintText: 'Section or class',
                        ),
                        const SizedBox(height: 18),
                        AppButton(
                          onPressed: _isStarting ? null : _startQuiz,
                          text: 'Start Test',
                          icon: Icons.play_arrow,
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
