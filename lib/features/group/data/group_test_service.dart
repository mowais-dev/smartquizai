import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_database/firebase_database.dart';

class GroupTestService {
  const GroupTestService();

  DatabaseReference get _testsRef =>
      FirebaseDatabase.instance.ref().child('group_tests');
  DatabaseReference get _topicsRef =>
      FirebaseDatabase.instance.ref().child('group_topics');
  DatabaseReference get _resultsRef =>
      FirebaseDatabase.instance.ref().child('group_test_results');

  String buildShareUrl(String testId) {
    return 'https://smartquiz.app/join?testId=$testId';
  }

  String? parseSharedTestId(String url) {
    try {
      final uri = Uri.parse(url.trim());
      return uri.queryParameters['testId'];
    } catch (_) {
      return null;
    }
  }

  Future<String> createTopic({
    required String title,
    required String explanation,
    Uint8List? imageBytes,
    String? imageMimeType,
    String? documentName,
    String? documentText,
    required String teacherId,
    required String teacherEmail,
  }) async {
    final ref = _topicsRef.push();
    final topicData = {
      'title': title,
      'explanation': explanation,
      'teacherId': teacherId,
      'teacherEmail': teacherEmail,
      'createdAt': DateTime.now().toIso8601String(),
      if (imageBytes != null && imageMimeType != null)
        'imageBase64': base64Encode(imageBytes),
      if (imageMimeType != null) 'imageMimeType': imageMimeType,
      if (documentName != null) 'documentName': documentName,
      if (documentText != null) 'documentText': documentText,
    };
    await ref.set(topicData);
    return ref.key!;
  }

  Future<String> createTest({
    required String title,
    required String description,
    Uint8List? imageBytes,
    String? imageMimeType,
    String? documentName,
    String? documentText,
    required String quizType,
    required String difficulty,
    required int questionCount,
    required int timerSeconds,
    required DateTime startAt,
    required DateTime endAt,
    required List<Map<String, dynamic>> questions,
    required String teacherId,
    required String teacherEmail,
  }) async {
    final ref = _testsRef.push();
    final testData = {
      'title': title,
      'description': description,
      'quizType': quizType,
      'difficulty': difficulty,
      'questionCount': questionCount,
      'timerSeconds': timerSeconds,
      'startAt': startAt.toIso8601String(),
      'endAt': endAt.toIso8601String(),
      'questions': questions,
      'teacherId': teacherId,
      'teacherEmail': teacherEmail,
      'createdAt': DateTime.now().toIso8601String(),
      if (imageBytes != null && imageMimeType != null)
        'imageBase64': base64Encode(imageBytes),
      if (imageMimeType != null) 'imageMimeType': imageMimeType,
      if (documentName != null) 'documentName': documentName,
      if (documentText != null) 'documentText': documentText,
    };
    await ref.set(testData);
    return ref.key!;
  }

  Future<List<Map<String, dynamic>>> fetchTopics({String? teacherId}) async {
    try {
      final snapshot = teacherId != null
          ? await _topicsRef.orderByChild('teacherId').equalTo(teacherId).get()
          : await _topicsRef.get();
      return _normalizeList(snapshot.value);
    } catch (_) {
      if (teacherId == null) {
        rethrow;
      }
      final snapshot = await _topicsRef.get();
      final allTopics = _normalizeList(snapshot.value);
      return allTopics
          .where((topic) => topic['teacherId'] == teacherId)
          .toList();
    }
  }

  Future<List<Map<String, dynamic>>> fetchTests({String? teacherId}) async {
    try {
      final snapshot = teacherId != null
          ? await _testsRef.orderByChild('teacherId').equalTo(teacherId).get()
          : await _testsRef.get();
      return _normalizeList(snapshot.value);
    } catch (_) {
      if (teacherId == null) {
        rethrow;
      }
      final snapshot = await _testsRef.get();
      final allTests = _normalizeList(snapshot.value);
      return allTests.where((test) => test['teacherId'] == teacherId).toList();
    }
  }

  Future<Map<String, dynamic>> fetchTestById(String id) async {
    final snapshot = await _testsRef.child(id).get();
    if (!snapshot.exists || snapshot.value == null) {
      throw Exception('Shared test not found');
    }
    return _normalizeItem(id, snapshot.value);
  }

  Future<List<Map<String, dynamic>>> fetchStudentResults(String testId) async {
    final snapshot = await _resultsRef.child(testId).get();
    return _normalizeList(snapshot.value);
  }

  Future<String> saveStudentResult({
    required String testId,
    required String studentName,
    required String studentRoll,
    String? studentSection,
    required int score,
    required int totalQuestions,
    required String topicTitle,
    required String quizType,
    List<int>? answers,
    List<Map<String, dynamic>>? questions,
  }) async {
    final ref = _resultsRef.child(testId).push();
    final resultData = {
      'studentName': studentName,
      'studentRoll': studentRoll,
      'studentSection': studentSection ?? '',
      'score': score,
      'totalQuestions': totalQuestions,
      'percentage': ((score / totalQuestions) * 100).round(),
      'topicTitle': topicTitle,
      'quizType': quizType,
      'submittedAt': DateTime.now().toIso8601String(),
      if (answers != null) 'answers': answers,
      if (questions != null) 'questions': questions,
    };
    await ref.set(resultData);
    return ref.key!;
  }

  List<Map<String, dynamic>> _normalizeList(dynamic rawValue) {
    if (rawValue == null) return [];
    if (rawValue is Map) {
      return rawValue.entries.map((entry) {
        final value = entry.value;
        return _normalizeItem(entry.key.toString(), value);
      }).toList();
    }
    return [];
  }

  Map<String, dynamic> _normalizeItem(String id, dynamic rawValue) {
    if (rawValue is Map) {
      return {'id': id, ...rawValue.cast<String, dynamic>()};
    }
    return {'id': id, 'value': rawValue};
  }
}
