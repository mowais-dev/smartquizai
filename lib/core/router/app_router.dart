import 'package:go_router/go_router.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/service_locator.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/history/presentation/pages/history_detail_page.dart';
import '../../features/history/presentation/pages/history_page.dart';
import '../../features/group/presentation/pages/group_result_page.dart';
import '../../features/group/presentation/pages/group_test_join_page.dart';
import '../../features/group/presentation/pages/group_test_results_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/quiz/presentation/pages/quiz_page.dart';
import '../../features/quiz/presentation/pages/quiz_setup_page.dart';
import '../../features/result/presentation/pages/result_page.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/login',
    refreshListenable: sl<AuthService>(),
    redirect: (context, state) {
      final authService = sl<AuthService>();
      final signedIn = authService.isSignedIn;
      final loggingIn =
          state.uri.path == '/login' || state.uri.path == '/signup';

      if (!signedIn && !loggingIn) return '/login';
      if (signedIn && loggingIn) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupPage(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/quiz-setup',
        name: 'quizSetup',
        builder: (context, state) {
          final quizType = state.uri.queryParameters['type'] ?? 'text';
          final topic = state.uri.queryParameters['topic'];
          return QuizSetupPage(quizType: quizType, initialTopic: topic);
        },
      ),
      GoRoute(
        path: '/quiz',
        name: 'quiz',
        builder: (context, state) {
          final topic = state.uri.queryParameters['topic'] ?? '';
          final difficulty = state.uri.queryParameters['difficulty'] ?? 'easy';
          final questionCount =
              int.tryParse(state.uri.queryParameters['count'] ?? '') ?? 10;
          final timerEnabled = state.uri.queryParameters['timer'] == '1';
          final quizType = state.uri.queryParameters['type'] ?? 'text';
          final groupTestId = state.uri.queryParameters['groupTestId'];
          final studentName = state.uri.queryParameters['studentName'];
          final studentRoll = state.uri.queryParameters['studentRoll'];
          final studentSection = state.uri.queryParameters['studentSection'];
          final extra = state.extra;
          final imageBytes = extra is Map ? extra['imageBytes'] : null;
          final imageMimeType = extra is Map ? extra['imageMimeType'] : null;
          final documentText = extra is Map ? extra['documentText'] : null;
          final preloadedQuestions = extra is Map
              ? extra['preloadedQuestions'] as List<dynamic>?
              : null;
          return QuizPage(
            topic: topic,
            difficulty: difficulty,
            questionCount: questionCount,
            timerEnabled: timerEnabled,
            quizType: quizType,
            groupTestId: groupTestId,
            studentName: studentName,
            studentRoll: studentRoll,
            studentSection: studentSection,
            imageBytes: imageBytes,
            imageMimeType: imageMimeType,
            documentText: documentText,
            preloadedQuestions: preloadedQuestions,
          );
        },
      ),
      GoRoute(
        path: '/group-test/join',
        name: 'groupTestJoin',
        builder: (context, state) {
          final testId = state.uri.queryParameters['testId'] ?? '';
          return GroupTestJoinPage(testId: testId);
        },
      ),
      GoRoute(
        path: '/join',
        name: 'deepLinkJoin',
        builder: (context, state) {
          final testId = state.uri.queryParameters['testId'] ?? '';
          return GroupTestJoinPage(testId: testId);
        },
      ),
      GoRoute(
        path: '/group-result',
        name: 'groupResult',
        builder: (context, state) {
          final score =
              int.tryParse(state.uri.queryParameters['score'] ?? '0') ?? 0;
          final total =
              int.tryParse(state.uri.queryParameters['total'] ?? '0') ?? 0;
          final topic = state.uri.queryParameters['topic'] ?? '';
          final testId = state.uri.queryParameters['testId'] ?? '';
          final studentName = state.uri.queryParameters['studentName'] ?? '';
          final studentRoll = state.uri.queryParameters['studentRoll'] ?? '';
          final studentSection = state.uri.queryParameters['studentSection'];
          final quizType = state.uri.queryParameters['quizType'] ?? 'text';
          final extra = state.extra;
          final answers = extra is Map ? extra['answers'] as List<int>? : null;
          final questions = extra is Map
              ? extra['questions'] as List<Map<String, dynamic>>?
              : null;
          return GroupResultPage(
            score: score,
            totalQuestions: total,
            topic: topic,
            testId: testId,
            studentName: studentName,
            studentRoll: studentRoll,
            studentSection: studentSection,
            quizType: quizType,
            answers: answers,
            questions: questions,
          );
        },
      ),
      GoRoute(
        path: '/group-test/results',
        name: 'groupTestResults',
        builder: (context, state) {
          final testId = state.uri.queryParameters['testId'] ?? '';
          return GroupTestResultsPage(testId: testId);
        },
      ),
      GoRoute(
        path: '/result',
        name: 'result',
        builder: (context, state) {
          final score =
              int.tryParse(state.uri.queryParameters['score'] ?? '0') ?? 0;
          final total =
              int.tryParse(state.uri.queryParameters['total'] ?? '0') ?? 0;
          final topic = state.uri.queryParameters['topic'] ?? '';
          return ResultPage(score: score, totalQuestions: total, topic: topic);
        },
      ),
      GoRoute(
        path: '/history',
        name: 'history',
        builder: (context, state) => const HistoryPage(),
      ),
      GoRoute(
        path: '/history/detail',
        name: 'historyDetail',
        builder: (context, state) {
          final item = state.extra as Map<String, dynamic>?;
          return HistoryDetailPage(historyItem: item ?? <String, dynamic>{});
        },
      ),
    ],
  );
}
