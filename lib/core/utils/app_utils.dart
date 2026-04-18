import 'dart:convert';

import '../error/failure.dart';

class AppUtils {
  // JSON parsing utilities
  static T fromJson<T>(String json, T Function(Map<String, dynamic>) fromJson) {
    try {
      final Map<String, dynamic> data = jsonDecode(json);
      return fromJson(data);
    } catch (e) {
      throw const ValidationFailure(message: 'Invalid JSON format');
    }
  }

  static String toJson(Object object) {
    try {
      return jsonEncode(object);
    } catch (e) {
      throw const ValidationFailure(message: 'Failed to convert to JSON');
    }
  }

  // Date formatting utilities
  static String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  static String formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  static String formatDateTime(DateTime date) {
    return '${formatDate(date)} ${formatTime(date)}';
  }

  // Percentage calculation
  static int calculatePercentage(int score, int total) {
    if (total == 0) return 0;
    return ((score / total) * 100).round();
  }

  // Validation utilities
  static bool isValidTopic(String topic) {
    return topic.trim().length >= 3;
  }

  static String? validateTopic(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Topic is required';
    }
    if (value.trim().length < 3) {
      return 'Topic must be at least 3 characters long';
    }
    return null;
  }

  // Error handling utilities
  static Failure handleException(Exception exception) {
    if (exception is FormatException) {
      return const ValidationFailure(message: 'Invalid data format');
    }
    return UnknownFailure(message: exception.toString());
  }

  // String utilities
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}
