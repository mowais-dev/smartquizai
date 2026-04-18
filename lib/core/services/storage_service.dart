import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

class StorageService {
  static const String quizHistoryBox = 'quiz_history';
  static const String settingsBox = 'settings';

  static Future<void> init() async {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    Hive.init(appDocumentDir.path);

    // Register adapters here if needed
    // Hive.registerAdapter(QuizHistoryAdapter());

    await Hive.openBox(quizHistoryBox);
    await Hive.openBox(settingsBox);
  }

  // Quiz History Methods
  static Future<void> saveQuizResult({
    required String topic,
    required String quizType,
    required int score,
    required int totalQuestions,
    required DateTime date,
    String? firebaseId,
  }) async {
    final box = Hive.box(quizHistoryBox);
    final quizData = {
      'topic': topic,
      'quizType': quizType,
      'score': score,
      'totalQuestions': totalQuestions,
      'date': date.toIso8601String(),
      'percentage': (score / totalQuestions * 100).round(),
      if (firebaseId != null) 'id': firebaseId,
    };

    await box.add(quizData);
  }

  static List<Map<String, dynamic>> getQuizHistory() {
    final box = Hive.box(quizHistoryBox);
    final items = <Map<String, dynamic>>[];
    for (var i = 0; i < box.length; i++) {
      final key = box.keyAt(i);
      final value = box.get(key);
      if (value is Map) {
        items.add({
          ...Map<String, dynamic>.from(value.cast()),
          'hiveKey': key,
        });
      }
    }
    return items;
  }

  static Future<void> deleteQuizHistoryItem(dynamic hiveKey) async {
    final box = Hive.box(quizHistoryBox);
    await box.delete(hiveKey);
  }

  static Future<void> clearQuizHistory() async {
    final box = Hive.box(quizHistoryBox);
    await box.clear();
  }

  // Settings Methods
  static Future<void> saveSetting(String key, dynamic value) async {
    final box = Hive.box(settingsBox);
    await box.put(key, value);
  }

  static dynamic getSetting(String key, {dynamic defaultValue}) {
    final box = Hive.box(settingsBox);
    return box.get(key, defaultValue: defaultValue);
  }

  // Generic methods for other features
  static Future<void> saveData(
    String boxName,
    String key,
    dynamic value,
  ) async {
    final box = await Hive.openBox(boxName);
    await box.put(key, value);
  }

  static dynamic getData(String boxName, String key, {dynamic defaultValue}) {
    final box = Hive.box(boxName);
    return box.get(key, defaultValue: defaultValue);
  }

  static Future<void> deleteData(String boxName, String key) async {
    final box = Hive.box(boxName);
    await box.delete(key);
  }
}
