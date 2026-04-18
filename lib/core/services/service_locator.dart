import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import 'package:smartquizai/core/services/auth_service.dart';
import 'package:smartquizai/features/group/data/group_test_service.dart';
import 'package:smartquizai/features/quiz/presentation/bloc/quiz_bloc.dart';
import 'package:smartquizai/features/quiz/data/datasources/quiz_firebase_data_source.dart';
import 'package:smartquizai/features/quiz/data/datasources/quiz_local_data_source.dart';
import 'package:smartquizai/features/quiz/data/datasources/quiz_remote_data_source.dart';
import 'package:smartquizai/features/quiz/data/repositories/quiz_repository_impl.dart';
import 'package:smartquizai/features/quiz/domain/repositories/quiz_repository.dart';
import 'package:smartquizai/features/quiz/domain/usecases/generate_quiz.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // BLoC
  sl.registerFactory(
    () => QuizBloc(generateQuizUseCase: sl(), saveQuizResultUseCase: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GenerateQuizUseCase(sl()));
  sl.registerLazySingleton(() => SaveQuizResultUseCase(sl()));

  // Repository
  sl.registerLazySingleton<QuizRepository>(
    () => QuizRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      firebaseDataSource: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<QuizRemoteDataSource>(
    () => QuizRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<QuizLocalDataSource>(
    () => const QuizLocalDataSourceImpl(),
  );
  sl.registerLazySingleton<QuizFirebaseDataSource>(
    () => const QuizFirebaseDataSourceImpl(),
  );

  // External
  sl.registerLazySingleton(() => AuthService());
  sl.registerLazySingleton(() => const GroupTestService());
  sl.registerLazySingleton(() => Dio());
}
