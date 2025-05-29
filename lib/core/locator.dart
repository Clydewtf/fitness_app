import 'package:fitness_app/logic/workout_bloc/workout_bloc.dart';
import 'package:fitness_app/services/achievement_service.dart';
import 'package:get_it/get_it.dart';
import '../data/repositories/photo_progress_repository.dart';
import '../data/repositories/workout_log_repository.dart';
import '../logic/progress_bloc/photo_progress_cubit.dart';
import '../logic/workout_bloc/my_workout_bloc.dart';
import '../services/auth_service.dart';
import '../services/daily_workout_service.dart';
import '../services/user_service.dart';
import '../data/repositories/exercise_repository.dart';
import '../data/repositories/workout_repository.dart';
import '../data/repositories/nutrition_repository.dart';
import '../logic/auth_bloc/auth_bloc.dart';
import '../logic/nutrition_bloc/nutrition_bloc.dart';
import '../logic/notification_bloc/notification_bloc.dart';
import '../services/notification_service.dart'; 
import '../logic/workout_bloc/exercise_bloc.dart';
import '../data/repositories/my_workout_repository.dart';

final GetIt locator = GetIt.instance;

void setupLocator() {
  // Регистрация сервисов
  locator.registerLazySingleton<AuthService>(() => AuthService());
  locator.registerLazySingleton<UserService>(() => UserService());
  locator.registerLazySingleton<NotificationService>(() => NotificationService());
  locator.registerLazySingleton<DailyWorkoutService>(() => DailyWorkoutService());
  locator.registerLazySingleton<AchievementService>(() => AchievementService());
  locator.registerLazySingleton<DailyWorkoutRefreshCubit>(() => DailyWorkoutRefreshCubit());

  // Регистрация репозиториев (синглтоны)
  locator.registerLazySingleton<WorkoutRepository>(() => WorkoutRepository());
  locator.registerLazySingleton<ExerciseRepository>(() => ExerciseRepository());
  locator.registerLazySingleton<NutritionRepository>(() => NutritionRepository());
  locator.registerLazySingleton<MyWorkoutRepository>(() => MyWorkoutRepository());
  locator.registerLazySingleton<WorkoutLogRepository>(() => WorkoutLogRepository());
  locator.registerLazySingleton<PhotoProgressRepository>(() => PhotoProgressRepository());

  // Регистрация BLoC (создаются каждый раз при запросе)
  locator.registerFactory(() => AuthBloc(locator<AuthService>()));
  locator.registerFactory(() => ExerciseBloc(exerciseRepository: locator<ExerciseRepository>()));
  locator.registerFactory(() => NutritionBloc(locator<NutritionRepository>()));
  locator.registerFactory(() => NotificationBloc(notificationService: locator<NotificationService>()));
  locator.registerFactory(() => MyWorkoutBloc(locator<MyWorkoutRepository>()));
  locator.registerFactory(() => WorkoutBloc(
    workoutRepository: locator<WorkoutRepository>(),
    userService: locator<UserService>(),
    uid: locator<AuthService>().getCurrentUser()?.uid ?? '',
  ));
  locator.registerFactory(() => PhotoProgressCubit(repository: locator<PhotoProgressRepository>()));
}