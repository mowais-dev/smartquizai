import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failure.dart';
import '../models/question_model.dart';

abstract class QuizRemoteDataSource {
  Future<List<QuestionModel>> generateQuiz(
    String topic, {
    required String difficulty,
    required int questionCount,
    required String quizType,
    Uint8List? imageBytes,
    String? imageMimeType,
    String? documentText,
  });
}

class QuizRemoteDataSourceImpl implements QuizRemoteDataSource {
  const QuizRemoteDataSourceImpl(this.dio);

  final Dio dio;

  @override
  Future<List<QuestionModel>> generateQuiz(
    String topic, {
    required String difficulty,
    required int questionCount,
    required String quizType,
    Uint8List? imageBytes,
    String? imageMimeType,
    String? documentText,
  }) async {
    const maxRetries = AppConstants.maxApiRetries;
    var retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        final isImageQuiz = quizType == 'image' && imageBytes != null;
        final isDocumentQuiz = quizType == 'document' &&
            documentText != null &&
            documentText.trim().isNotEmpty;

        final systemPrompt =
            'You are a quiz generator.\n'
            'Output requirements:\n'
            '- Generate exactly $questionCount MCQs.\n'
            '- Each MCQ has exactly 4 options.\n'
            '- Provide a 0-based "correctAnswer" index.\n'
            '- Provide a short "explanation".\n'
            '- Return ONLY valid JSON (no markdown, no extra text) in this format:\n'
            '{"questions":[{"question":"...","options":["A","B","C","D"],"correctAnswer":0,"explanation":"..."}]}.\n'
            '\n'
            'Strict behavior rules:\n'
            '- NEVER ask meta-questions about the source (e.g. "what type of questions are shown", "what is the topic", "what is mentioned in the questions").\n'
            '- NEVER refer to the source itself (avoid phrases like "in the image", "in the document", "in the text above").\n'
            '- Treat the provided source as SOURCE MATERIAL: extract the content and convert it into clean MCQs.\n'
            '- If the source contains questions, convert each into an MCQ that tests the same concept.\n'
            '- If the source contains notes/definitions, create MCQs that test those facts.\n'
            '- If the source contains fewer than $questionCount items, create additional MCQs in the same subject area inferred from the extracted content.\n'
            '- If the source contains more than $questionCount items, pick the most important ones.\n'
            '- Avoid tricks; ensure exactly one correct option per question.';

        final requestData = <String, dynamic>{
          'model': isImageQuiz
              ? AppConstants.visionModel
              : AppConstants.chatGptModel,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            if (isImageQuiz) ...[
              {
                'role': 'user',
                'content': [
                  {
                    'type': 'text',
                    'text':
                        'Convert the provided content into MCQs.\n'
                        'Do NOT create questions about the image or about "what is shown".\n'
                        'Only produce knowledge-check MCQs derived from the content.',
                  },
                  {
                    'type': 'image_url',
                    'image_url': {
                      'url': _asDataUrl(
                        imageBytes,
                        mimeType: imageMimeType ?? 'image/png',
                      ),
                    },
                  },
                ],
              },
            ] else if (isDocumentQuiz) ...[
              {
                'role': 'user',
                'content':
                    'Convert the following document content into MCQs.\n'
                    'Do NOT ask meta-questions about the document (e.g., "what type of questions", "what is the topic").\n'
                    'Only generate MCQs that test the knowledge in the text.\n'
                    '\n'
                    'DOCUMENT_TEXT:\n'
                    '${_clipDocument(documentText!, maxChars: 14000)}',
              },
            ] else ...[
              {
                'role': 'user',
                'content':
                    'Generate exactly $questionCount multiple choice questions about the topic "$topic". '
                    'Design the quiz as a $quizType quiz.',
              },
            ],
          ],
          'temperature': isImageQuiz ? 0.3 : 0.7,
        };

        if (kDebugMode) {
          print(
            'ChatGPT request URL: ${AppConstants.openAiBaseUrl}/chat/completions',
          );
          print('ChatGPT request payload: ${jsonEncode(requestData)}');
          print('Retry attempt: ${retryCount + 1}/${maxRetries}');
        }

        final response = await dio.post(
          '${AppConstants.openAiBaseUrl}/chat/completions',
          data: requestData,
          options: Options(
            headers: {
              'Authorization': 'Bearer ${AppConstants.openAiApiKey}',
              'Content-Type': 'application/json',
            },
          ),
        );

        if (kDebugMode) {
          print('ChatGPT response status: ${response.statusCode}');
          print('ChatGPT response data: ${response.data}');
        }

        if (response.statusCode == 200) {
          final data = response.data;
          try {
            final content = data['choices'][0]['message']['content'] as String;

            if (kDebugMode) {
              print('ChatGPT raw content: $content');
            }

            // Parse the JSON response
            final quizData = jsonDecode(content) as Map<String, dynamic>;
            final questions = quizData['questions'] as List;

            return questions
                .map(
                  (q) => QuestionModel.fromJson({
                    ...q as Map<String, dynamic>,
                    'id':
                        DateTime.now().millisecondsSinceEpoch.toString() +
                        questions.indexOf(q).toString(),
                  }),
                )
                .toList();
          } catch (e) {
            if (kDebugMode) {
              print('JSON parsing error: $e');
              print(
                'Raw content that failed to parse: ${data['choices'][0]['message']['content']}',
              );
            }

            // Fallback: Generate basic questions if AI response is malformed
            if (kDebugMode) {
              print(
                'Using fallback questions due to malformed ChatGPT response',
              );
            }

            return _generateFallbackQuestions(
              isImageQuiz ? 'this image' : topic,
            );
          }
        } else if (response.statusCode == 429) {
          // Rate limit exceeded - retry with exponential backoff
          retryCount++;
          if (retryCount < maxRetries) {
            final delaySeconds =
                AppConstants.baseRetryDelaySeconds * retryCount; // 2s, 4s, 6s
            if (kDebugMode) {
              print('Rate limit exceeded. Retrying in ${delaySeconds}s...');
            }
            await Future.delayed(Duration(seconds: delaySeconds));
            continue;
          } else {
            throw ServerFailure(message: AppConstants.rateLimitError);
          }
        } else {
          throw ServerFailure(
            message: 'Failed to generate quiz: ${response.statusCode}',
          );
        }
      } catch (e) {
        if (e is ServerFailure) {
          rethrow;
        }
        retryCount++;
        if (retryCount < maxRetries) {
          final delaySeconds =
              AppConstants.baseRetryDelaySeconds * retryCount; // 2s, 4s, 6s
          if (kDebugMode) {
            print('Request failed: $e. Retrying in ${delaySeconds}s...');
          }
          await Future.delayed(Duration(seconds: delaySeconds));
          continue;
        } else {
          throw ServerFailure(message: e.toString());
        }
      }
    }

    // This should never be reached, but just in case
    throw ServerFailure(message: 'Max retries exceeded');
  }

  List<QuestionModel> _generateFallbackQuestions(String topic) {
    // Generate basic fallback questions when ChatGPT fails
    final fallbackQuestions = [
      {
        'question': 'This is a sample question about $topic. What is 2 + 2?',
        'options': ['3', '4', '5', '6'],
        'correctAnswer': 1,
        'explanation':
            '2 + 2 equals 4 in basic arithmetic. (This is a fallback question)',
      },
      {
        'question': 'Sample question: Which planet is known as the Red Planet?',
        'options': ['Venus', 'Mars', 'Jupiter', 'Saturn'],
        'correctAnswer': 1,
        'explanation':
            'Mars is known as the Red Planet due to its reddish appearance. (This is a fallback question)',
      },
      {
        'question': 'Fallback question: What is the capital of France?',
        'options': ['London', 'Berlin', 'Paris', 'Madrid'],
        'correctAnswer': 2,
        'explanation':
            'Paris is the capital of France. (This is a fallback question)',
      },
      {
        'question': 'Sample: Which ocean is the largest?',
        'options': [
          'Atlantic Ocean',
          'Indian Ocean',
          'Arctic Ocean',
          'Pacific Ocean',
        ],
        'correctAnswer': 3,
        'explanation':
            'The Pacific Ocean is the largest ocean on Earth. (This is a fallback question)',
      },
      {
        'question': 'Fallback: What is the chemical symbol for water?',
        'options': ['H2O', 'CO2', 'O2', 'NaCl'],
        'correctAnswer': 0,
        'explanation':
            'H2O is the chemical formula for water. (This is a fallback question)',
      },
    ];

    return fallbackQuestions
        .map(
          (q) => QuestionModel.fromJson({
            ...q,
            'id':
                DateTime.now().millisecondsSinceEpoch.toString() +
                fallbackQuestions.indexOf(q).toString(),
          }),
        )
        .toList();
  }

  String _asDataUrl(Uint8List bytes, {required String mimeType}) {
    final encoded = base64Encode(bytes);
    return 'data:$mimeType;base64,$encoded';
  }

  String _clipDocument(String text, {required int maxChars}) {
    final trimmed = text.trim();
    if (trimmed.length <= maxChars) return trimmed;
    return '${trimmed.substring(0, maxChars)}\n\n[TRUNCATED]';
  }
}
