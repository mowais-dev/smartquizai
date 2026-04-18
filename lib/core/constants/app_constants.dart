class AppConstants {
  // API Constants
  static const String openAiBaseUrl = 'https://api.openai.com/v1';
  static const String chatGptModel = 'gpt-3.5-turbo';
  static const String visionModel = 'gpt-4o-mini';
  static const String openAiApiKey = 'YOUR_API_KEY';

  // Storage Keys
  static const String quizHistoryKey = 'quiz_history';
  static const String themeKey = 'theme_mode';

  // Route Names
  static const String homeRoute = '/';
  static const String quizRoute = '/quiz';
  static const String resultRoute = '/result';
  static const String historyRoute = '/history';

  // Quiz Constants
  static const int defaultQuestionCount = 10;
  static const int maxQuestionCount = 30;
  static const int defaultQuestionDurationSeconds = 20;
  static const int quizTimeLimit = 600; // 10 minutes in seconds

  // API Retry Constants
  static const int maxApiRetries = 3;
  static const int baseRetryDelaySeconds = 2;

  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
  static const double defaultElevation = 4.0;

  // Error Messages
  static const String networkError =
      'Network connection failed. Please check your internet connection.';
  static const String serverError = 'Server error. Please try again later.';
  static const String unknownError =
      'An unknown error occurred. Please try again.';
  static const String rateLimitError =
      'API rate limit exceeded. Please wait a moment and try again, or consider upgrading your Google AI plan for higher limits.';

  // Success Messages
  static const String quizCompleted = 'Quiz completed successfully!';
  static const String dataSaved = 'Data saved successfully!';

  // Validation Messages
  static const String topicRequired = 'Please enter a quiz topic';
  static const String topicTooShort =
      'Topic must be at least 3 characters long';
}
