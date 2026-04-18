import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smartquizai/core/services/auth_service.dart';
import 'package:smartquizai/core/services/service_locator.dart';
import 'package:smartquizai/core/theme/app_gradients.dart';
import 'package:smartquizai/features/quiz/domain/usecases/generate_quiz.dart';
import 'package:smartquizai/core/theme/app_palette.dart';
import 'package:smartquizai/features/group/data/group_test_service.dart';
import 'package:smartquizai/shared/widgets/app_button.dart';
import 'package:smartquizai/shared/widgets/app_card.dart';
import 'package:smartquizai/shared/widgets/app_text_field.dart';
import 'package:smartquizai/shared/widgets/gradient_background.dart';
import 'package:smartquizai/shared/widgets/glass_container.dart';
import 'package:go_router/go_router.dart';

class GroupTestsTab extends StatefulWidget {
  const GroupTestsTab({super.key});

  @override
  State<GroupTestsTab> createState() => _GroupTestsTabState();
}

class _GroupTestsTabState extends State<GroupTestsTab> {
  final _testTitleController = TextEditingController();
  final _testDescriptionController = TextEditingController();
  final _shareUrlController = TextEditingController();
  final _openUrlController = TextEditingController();

  final _picker = ImagePicker();

  String _selectedDifficulty = 'easy';
  String _selectedQuizType = 'text';
  int _questionCount = 10;
  int _timerSeconds = 0;

  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  String? _selectedImageMime;

  PlatformFile? _selectedDocument;
  String? _selectedDocumentText;

  bool _isLoading = false;
  bool _isCreatingTest = false;
  bool _isGeneratingQuestions = false;
  String? _shareUrl;
  String? _previewError;

  DateTime? _startAt;
  DateTime? _endAt;
  List<Map<String, dynamic>> _previewQuestions = [];
  List<Map<String, dynamic>> _tests = [];

  GroupTestService get _service => sl<GroupTestService>();
  AuthService get _authService => sl<AuthService>();

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
  }

  @override
  void dispose() {
    _testTitleController.dispose();
    _testDescriptionController.dispose();
    _shareUrlController.dispose();
    _openUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadTeacherData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final user = _authService.currentUser;
      if (user == null) {
        return;
      }
      final tests = await _service.fetchTests(teacherId: user.uid);
      tests.sort(
        (a, b) =>
            b['createdAt'].toString().compareTo(a['createdAt'].toString()),
      );
      setState(() {
        _tests = tests;
      });
    } catch (_) {
      // ignore load errors
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _selectedImage = file;
        _selectedImageBytes = bytes;
        final name = file.name.toLowerCase();
        _selectedImageMime = name.endsWith('.jpg') || name.endsWith('.jpeg')
            ? 'image/jpeg'
            : 'image/png';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Image pick failed: $e')));
    }
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        withData: true,
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'docx', 'txt', 'md'],
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.bytes == null) {
        throw Exception('Unable to read document');
      }
      String documentText = '';
      if (file.extension == 'pdf') {
        documentText = 'Uploaded PDF: ${file.name}';
      } else {
        documentText = utf8.decode(file.bytes!, allowMalformed: true);
      }
      if (!mounted) return;
      setState(() {
        _selectedDocument = file;
        _selectedDocumentText = documentText.trim();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Document pick failed: $e')));
    }
  }

  Future<void> _generateQuestionPreview() async {
    final title = _testTitleController.text.trim();
    final description = _testDescriptionController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Test title is required.')));
      return;
    }
    if (_selectedQuizType == 'image' && _selectedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please attach an image for image quizzes.'),
        ),
      );
      return;
    }
    if (_selectedQuizType == 'document' &&
        (_selectedDocumentText == null || _selectedDocumentText!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please attach a document for document quizzes.'),
        ),
      );
      return;
    }

    setState(() {
      _isGeneratingQuestions = true;
      _previewError = null;
    });

    final prompt = description.isEmpty ? title : '$title\n\n$description';
    try {
      final result = await sl<GenerateQuizUseCase>().call(
        prompt,
        difficulty: _selectedDifficulty,
        questionCount: _questionCount,
        quizType: _selectedQuizType,
        imageBytes: _selectedImageBytes,
        imageMimeType: _selectedImageMime,
        documentText: _selectedDocumentText,
      );

      result.fold(
        (failure) {
          if (!mounted) return;
          setState(() {
            _previewError = failure.message;
            _previewQuestions = [];
          });
        },
        (quizResult) {
          setState(() {
            _previewQuestions = quizResult.questions.map((question) {
              return {
                'id': question.id,
                'question': question.question,
                'options': question.options,
                'correctAnswer': question.correctAnswer,
                'explanation': question.explanation ?? '',
              };
            }).toList();
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _previewError = e.toString();
        _previewQuestions = [];
      });
    } finally {
      if (mounted) setState(() => _isGeneratingQuestions = false);
    }
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    if (time == null) return;
    final combined = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    if (!mounted) return;
    setState(() {
      if (isStart) {
        _startAt = combined;
      } else {
        _endAt = combined;
      }
    });
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Not set';
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _addCustomQuestion() async {
    final questionController = TextEditingController();
    final optionControllers = List.generate(4, (_) => TextEditingController());
    int selectedCorrectIndex = 0;

    final added = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add custom question'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: questionController,
                      decoration: const InputDecoration(labelText: 'Question'),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(4, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TextFormField(
                          controller: optionControllers[index],
                          decoration: InputDecoration(
                            labelText: 'Option ${index + 1}',
                            suffixIcon: Radio<int>(
                              value: index,
                              groupValue: selectedCorrectIndex,
                              onChanged: (value) {
                                if (value == null) return;
                                setDialogState(() {
                                  selectedCorrectIndex = value;
                                });
                              },
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final questionText = questionController.text.trim();
                    final options = optionControllers
                        .map((c) => c.text.trim())
                        .toList();
                    if (questionText.isEmpty ||
                        options.any((option) => option.isEmpty)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please fill the question and all options.',
                          ),
                        ),
                      );
                      return;
                    }
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );

    if (added != true) return;

    final questionText = questionController.text.trim();
    final options = optionControllers.map((c) => c.text.trim()).toList();
    setState(() {
      _previewQuestions.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'question': questionText,
        'options': options,
        'correctAnswer': selectedCorrectIndex,
        'explanation': '',
      });
    });
  }

  void _removePreviewQuestion(int index) {
    setState(() {
      _previewQuestions.removeAt(index);
    });
  }

  Future<void> _createTest() async {
    final user = _authService.currentUser;
    if (user == null) return;
    final title = _testTitleController.text.trim();
    final description = _testDescriptionController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Test title is required.')));
      return;
    }
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test description is required.')),
      );
      return;
    }
    if (_previewQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generate or add questions before creating the test.'),
        ),
      );
      return;
    }
    if (_startAt == null || _endAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose start and end times for this test.'),
        ),
      );
      return;
    }
    if (!_startAt!.isBefore(_endAt!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Start time must be before end time.')),
      );
      return;
    }

    setState(() => _isCreatingTest = true);
    try {
      final testId = await _service.createTest(
        title: title,
        description: description,
        quizType: _selectedQuizType,
        difficulty: _selectedDifficulty,
        questionCount: _previewQuestions.length,
        timerSeconds: _timerSeconds,
        startAt: _startAt!,
        endAt: _endAt!,
        questions: _previewQuestions,
        imageBytes: _selectedImageBytes,
        imageMimeType: _selectedImageMime,
        documentName: _selectedDocument?.name,
        documentText: _selectedDocumentText,
        teacherId: user.uid,
        teacherEmail: user.email ?? '',
      );
      final shareUrl = _service.buildShareUrl(testId);
      setState(() {
        _shareUrl = shareUrl;
        _shareUrlController.text = shareUrl;
        _testTitleController.clear();
        _testDescriptionController.clear();
        _selectedImage = null;
        _selectedImageBytes = null;
        _selectedImageMime = null;
        _selectedDocument = null;
        _selectedDocumentText = null;
        _previewQuestions = [];
        _startAt = null;
        _endAt = null;
      });
      await _loadTeacherData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Group test created and shareable link generated.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to create test: $e')));
    } finally {
      if (mounted) setState(() => _isCreatingTest = false);
    }
  }

  void _openSharedTest() {
    final url = _openUrlController.text.trim();
    final testId = _service.parseSharedTestId(url);
    if (testId == null || testId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid shared test URL.')),
      );
      return;
    }
    context.go('/group-test/join?testId=$testId');
  }

  Future<void> _copyShareLink() async {
    final text = _shareUrlController.text.trim();
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share link copied to clipboard')),
    );
  }

  Future<void> _shareLink(String link) async {
    if (link.isEmpty) return;
    try {
      await SharePlus.instance.share(
        ShareParams(
          title: 'Join my SmartQuiz Group Test',
          text: 'Open this shared SmartQuiz test in the app:\n$link',
          subject: 'Join SmartQuiz Group Test',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to open share sheet: $e')));
    }
  }

  Widget _buildTopicForm() {
    return const SizedBox.shrink();
  }

  Widget _buildSavedTopicsSection() {
    return const SizedBox.shrink();
  }

  Widget _buildTestForm() {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create Group Test',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _testTitleController,
            labelText: 'Test title',
            hintText: 'Enter the quiz title',
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _testDescriptionController,
            labelText: 'Test description',
            hintText: 'Describe the quiz for students',
            maxLines: 4,
          ),
          const SizedBox(height: 12),
          AppButton(
            onPressed: _pickImage,
            text: _selectedImage == null ? 'Attach image' : 'Replace image',
            icon: Icons.photo,
          ),
          const SizedBox(height: 12),
          AppButton(
            onPressed: _pickDocument,
            text: _selectedDocument == null
                ? 'Attach document'
                : 'Replace document',
            icon: Icons.description,
          ),
          if (_selectedImage != null) ...[
            const SizedBox(height: 12),
            Text(
              'Image: ${_selectedImage!.name}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          if (_selectedDocument != null) ...[
            const SizedBox(height: 8),
            Text(
              'Document: ${_selectedDocument!.name}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 7,
                child: DropdownButtonFormField<String>(
                  value: _selectedQuizType,
                  decoration: const InputDecoration(labelText: 'Quiz type'),
                  items: const [
                    DropdownMenuItem(value: 'text', child: Text('Text')),
                    DropdownMenuItem(value: 'image', child: Text('Image')),
                    DropdownMenuItem(
                      value: 'document',
                      child: Text('Document'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedQuizType = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 5,
                child: TextFormField(
                  initialValue: _timerSeconds.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Timer sec'),
                  onChanged: (value) {
                    final seconds = int.tryParse(value) ?? 0;
                    setState(() => _timerSeconds = seconds.clamp(0, 3600));
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: _questionCount.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Question count',
                  ),
                  onChanged: (value) {
                    final count = int.tryParse(value) ?? 10;
                    setState(() => _questionCount = count.clamp(5, 50));
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedDifficulty,
                  decoration: const InputDecoration(labelText: 'Difficulty'),
                  items: const [
                    DropdownMenuItem(value: 'easy', child: Text('Easy')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'hard', child: Text('Hard')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedDifficulty = value;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppButton(
            onPressed: () => _pickDateTime(isStart: true),
            text: 'Start: ${_formatDateTime(_startAt)}',
            icon: Icons.play_circle_outline,
          ),
          const SizedBox(height: 16),

          AppButton(
            onPressed: () => _pickDateTime(isStart: false),
            text: 'End: ${_formatDateTime(_endAt)}',
            icon: Icons.stop_circle_outlined,
          ),

          const SizedBox(height: 16),
          AppButton(
            onPressed: _isGeneratingQuestions ? null : _generateQuestionPreview,
            text: 'Generate Questions',
            isLoading: _isGeneratingQuestions,
          ),
          if (_previewError != null) ...[
            const SizedBox(height: 12),
            Text(
              _previewError!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.redAccent),
            ),
          ],
          if (_previewQuestions.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              'Preview questions',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._previewQuestions.asMap().entries.map((entry) {
              final index = entry.key;
              final question = entry.value;
              final options =
                  (question['options'] as List<dynamic>?)
                      ?.map((opt) => opt.toString())
                      .toList() ??
                  [];
              return Dismissible(
                key: ValueKey(question['id'] ?? index),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => _removePreviewQuestion(index),
                background: Container(
                  color: AppPalette.error,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: GlassContainer(
                  borderRadius: 18,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Q${index + 1}: ${question['question']}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      ...options.asMap().entries.map((optionEntry) {
                        final optionIndex = optionEntry.key;
                        final optionText = optionEntry.value;
                        final isCorrect =
                            optionIndex ==
                            (int.tryParse(
                                  question['correctAnswer']?.toString() ?? '',
                                ) ??
                                0);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Icon(
                                isCorrect
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                size: 18,
                                color: isCorrect
                                    ? Colors.greenAccent
                                    : Colors.white70,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  optionText,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 10),
            AppButton(
              onPressed: _addCustomQuestion,
              text: 'Add a custom question',
              icon: Icons.add,
            ),
          ],
          const SizedBox(height: 16),
          AppButton(
            onPressed: _isCreatingTest ? null : _createTest,
            text: 'Create and Generate Link',
            isLoading: _isCreatingTest,
          ),
          const SizedBox(height: 14),
          if (_shareUrlController.text.isNotEmpty) ...[
            Text(
              'Shareable URL',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _shareUrlController,
              readOnly: true,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            AppButton(
              onPressed: _copyShareLink,
              text: 'Copy Link',
              icon: Icons.copy,
            ),
            const SizedBox(height: 10),
            AppButton(
              onPressed: () => _shareLink(_shareUrlController.text.trim()),
              text: 'Share Link',
              icon: Icons.share,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSharedUrlSection() {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Open shared test',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _openUrlController,
            labelText: 'Shared test URL',
            hintText: 'Paste the link here',
          ),
          const SizedBox(height: 12),
          AppButton(
            onPressed: _openSharedTest,
            text: 'Open Shared Test',
            icon: Icons.open_in_new,
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherTestsList() {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Group Tests',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          if (_tests.isEmpty) ...[
            Text(
              'No group tests created yet. Use the form above to generate a shareable test link.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppPalette.textSecondary),
            ),
          ] else ...[
            ..._tests.map((test) {
              final count = test['questionCount']?.toString() ?? '0';
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassContainer(
                  borderRadius: 20,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        test['title'] ?? 'Untitled',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Topic: ${test['topicTitle'] ?? ''}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppPalette.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          Chip(label: Text('Type: ${test['quizType'] ?? ''}')),
                          Chip(label: Text('Count: $count')),
                          Chip(
                            label: Text('Timer: ${test['timerSeconds'] ?? 0}s'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      AppButton(
                        onPressed: () {
                          context.go(
                            '/group-test/results?testId=${Uri.encodeQueryComponent(test['id'] as String)}',
                          );
                        },
                        text: 'View Student Results',
                        icon: Icons.people,
                      ),
                      const SizedBox(height: 10),
                      AppButton(
                        onPressed: () {
                          final shareUrl = _service.buildShareUrl(
                            test['id'] as String,
                          );
                          Clipboard.setData(ClipboardData(text: shareUrl));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Test link copied to clipboard.'),
                            ),
                          );
                        },
                        text: 'Copy link',
                        icon: Icons.copy,
                      ),
                      const SizedBox(height: 10),
                      AppButton(
                        onPressed: () {
                          final shareUrl = _service.buildShareUrl(
                            test['id'] as String,
                          );
                          _shareLink(shareUrl);
                        },
                        text: 'Share',
                        icon: Icons.share,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      gradient: AppGradients.deepPurpleToBlue,
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Teacher workspace',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create topics, build group tests, and share URLs with students.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppPalette.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildTestForm(),
                    const SizedBox(height: 20),
                    _buildSharedUrlSection(),
                    const SizedBox(height: 20),
                    _buildTeacherTestsList(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
      ),
    );
  }
}
