import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:xml/xml.dart';

import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/gradient_background.dart';
import '../../../../shared/widgets/glass_container.dart';

class QuizSetupPage extends StatefulWidget {
  const QuizSetupPage({
    super.key,
    required this.quizType,
    this.initialTopic,
  });

  final String quizType;
  final String? initialTopic;

  @override
  State<QuizSetupPage> createState() => _QuizSetupPageState();
}

class _QuizSetupPageState extends State<QuizSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _topicController = TextEditingController();
  final _questionCountController = TextEditingController(text: '10');
  String _selectedDifficulty = 'easy';
  bool _timerEnabled = false;
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  String? _selectedImageMime;
  final _picker = ImagePicker();

  PlatformFile? _selectedDocument;
  String? _documentText;

  @override
  void initState() {
    super.initState();
    if (widget.quizType != 'image' &&
        widget.initialTopic != null &&
        widget.initialTopic!.trim().isNotEmpty) {
      _topicController.text = widget.initialTopic!.trim();
    }
  }

  @override
  void dispose() {
    _topicController.dispose();
    _questionCountController.dispose();
    super.dispose();
  }

  void _startQuiz() {
    if (widget.quizType != 'image' &&
        widget.quizType != 'document' &&
        !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (widget.quizType == 'image' && _selectedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first')),
      );
      return;
    }

    if (widget.quizType == 'document' &&
        (_documentText == null || _documentText!.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a document first')),
      );
      return;
    }

    final topic = widget.quizType == 'image'
        ? 'Image Quiz'
        : widget.quizType == 'document'
            ? 'Document Quiz'
            : _topicController.text.trim();
    final questionCount = int.tryParse(_questionCountController.text.trim()) ?? 10;

    context.go(
      '/quiz?topic=${Uri.encodeQueryComponent(topic)}&difficulty=$_selectedDifficulty&count=$questionCount&timer=${_timerEnabled ? '1' : '0'}&type=${widget.quizType}',
      extra: widget.quizType == 'image'
          ? {
              'imageBytes': _selectedImageBytes,
              'imageMimeType': _selectedImageMime,
            }
          : widget.quizType == 'document'
              ? {
                  'documentText': _documentText,
                }
              : null,
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 92,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: GlassContainer(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          borderRadius: 20,
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take a photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        withData: true,
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'docx', 'doc', 'txt', 'md', 'csv', 'json'],
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;

      final bytes = file.bytes;
      if (bytes == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to read this file')),
        );
        return;
      }

      if (bytes.length > 6 * 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document is too large (max 6MB)')),
        );
        return;
      }

      final text = await _extractDocumentText(file, bytes);
      if (!mounted) return;
      setState(() {
        _selectedDocument = file;
        _documentText = text;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick document: $e')),
      );
    }
  }

  Future<String> _extractDocumentText(PlatformFile file, Uint8List bytes) async {
    final extension = (file.extension ?? '').toLowerCase();

    if (extension == 'pdf') {
      final document = PdfDocument(inputBytes: bytes);
      try {
        final extractor = PdfTextExtractor(document);
        return extractor.extractText();
      } finally {
        document.dispose();
      }
    }

    if (extension == 'docx') {
      final archive = ZipDecoder().decodeBytes(bytes);
      final docXml = archive.files.cast<ArchiveFile?>().firstWhere(
            (f) => (f?.name.toLowerCase() == 'word/document.xml'),
            orElse: () => null,
          );
      if (docXml == null) {
        throw Exception('Invalid DOCX (missing word/document.xml)');
      }

      final xmlString = utf8.decode(
        (docXml.content as List<int>),
        allowMalformed: true,
      );
      final xml = XmlDocument.parse(xmlString);
      final buffer = StringBuffer();

      final elements = xml.descendants.whereType<XmlElement>();
      for (final p in elements.where((e) => e.name.local == 'p')) {
        final textRuns = p.descendants
            .whereType<XmlElement>()
            .where((e) => e.name.local == 't')
            .map((e) => e.innerText)
            .where((t) => t.trim().isNotEmpty)
            .toList();
        if (textRuns.isEmpty) continue;
        buffer.writeln(textRuns.join().trim());
      }

      final out = buffer.toString().trim();
      if (out.isEmpty) {
        throw Exception('No text found in DOCX');
      }
      return out;
    }

    if (extension == 'doc') {
      throw Exception('DOC files are not supported yet. Please select a DOCX or PDF.');
    }

    return utf8.decode(bytes, allowMalformed: true);
  }

  String get _typeTitle {
    switch (widget.quizType) {
      case 'image':
        return 'Image Quiz';
      case 'document':
        return 'Document Quiz';
      default:
        return 'Text Quiz';
    }
  }

  String get _typeSubtitle {
    switch (widget.quizType) {
      case 'image':
        return 'Generate visually inspired quiz questions and practice image-style reasoning.';
      case 'document':
        return 'Generate MCQs directly from your notes or text documents.';
      default:
        return 'Generate fast text-based quizzes for general knowledge and study review.';
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
        extendBodyBehindAppBar: true,
        backgroundColor: AppPalette.background,
        appBar: AppBar(
          title: Text(_typeTitle),
          leading: IconButton(
            onPressed: () => context.go('/home'),
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: GradientBackground(
          gradient: AppGradients.indigoToCyan,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    _typeTitle,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _typeSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppPalette.textSecondary,
                          height: 1.35,
                        ),
                  ),
                  const SizedBox(height: 18),
                  GlassContainer(
                    borderRadius: 20,
                    padding: const EdgeInsets.all(18),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          if (widget.quizType == 'image') ...[
                            InkWell(
                              onTap: _showImageSourceSheet,
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.12),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.image_outlined),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _selectedImage == null
                                            ? 'Add an image (camera or gallery)'
                                            : _selectedImage!.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_ios, size: 16),
                                  ],
                                ),
                              ),
                            ),
                            if (_selectedImageBytes != null) ...[
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Image.memory(
                                  _selectedImageBytes!,
                                  height: 160,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ],
                          ] else if (widget.quizType == 'document') ...[
                            InkWell(
                              onTap: _pickDocument,
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.12),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.description_outlined),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _selectedDocument == null
                                            ? 'Add a document (txt/md/csv/json)'
                                            : (_selectedDocument!.name ?? 'Selected document'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_ios, size: 16),
                                  ],
                                ),
                              ),
                            ),
                            if (_documentText != null &&
                                _documentText!.trim().isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.04),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.10),
                                  ),
                                ),
                                child: Text(
                                  _documentText!.trim().length > 420
                                      ? '${_documentText!.trim().substring(0, 420)}...'
                                      : _documentText!.trim(),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppPalette.textSecondary,
                                        height: 1.35,
                                      ),
                                ),
                              ),
                            ],
                          ] else ...[
                            AppTextField(
                              controller: _topicController,
                              hintText: 'e.g., World History, Python Programming',
                              labelText: 'Quiz Topic',
                              prefixIcon: Icons.topic,
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a topic';
                                }
                                if (value.trim().length < 3) {
                                  return 'Topic must be at least 3 characters';
                                }
                                return null;
                              },
                            ),
                          ],
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedDifficulty,
                            decoration: const InputDecoration(
                              labelText: 'Difficulty Level',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'easy', child: Text('Easy')),
                              DropdownMenuItem(value: 'medium', child: Text('Medium')),
                              DropdownMenuItem(value: 'hard', child: Text('Hard')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedDifficulty = value);
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: _questionCountController,
                            hintText: 'Max 30 questions',
                            labelText: 'Number of Questions',
                            prefixIcon: Icons.format_list_numbered,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please choose number of questions';
                              }
                              final count = int.tryParse(value.trim());
                              if (count == null) {
                                return 'Enter a valid number';
                              }
                              if (count < 1 || count > 30) {
                                return 'Choose between 1 and 30 questions';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          Theme(
                            data: Theme.of(context).copyWith(
                              unselectedWidgetColor:
                                  AppPalette.textSecondary.withOpacity(0.9),
                            ),
                            child: CheckboxListTile(
                              value: _timerEnabled,
                              onChanged: (value) {
                                setState(() {
                                  _timerEnabled = value ?? false;
                                });
                              },
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              title: const Text('Enable timer'),
                              subtitle: Text(
                                'Adds a countdown to each question.',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppPalette.textSecondary,
                                    ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          AppButton(
                            text: 'Start Quiz',
                            icon: Icons.play_arrow,
                            onPressed: _startQuiz,
                          ),
                        ],
                      ),
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
