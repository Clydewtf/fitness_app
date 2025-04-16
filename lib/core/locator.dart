import 'package:get_it/get_it.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../data/repositories/exercise_repository.dart';
import '../data/repositories/workout_repository.dart';
import '../data/repositories/nutrition_repository.dart';
import '../logic/auth_bloc/auth_bloc.dart';
import '../logic/workout_bloc/workout_bloc.dart';
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

  // Регистрация репозиториев (синглтоны)
  locator.registerLazySingleton<WorkoutRepository>(() => WorkoutRepository());
  locator.registerLazySingleton<ExerciseRepository>(() => ExerciseRepository());
  locator.registerLazySingleton<NutritionRepository>(() => NutritionRepository());
  locator.registerLazySingleton<MyWorkoutRepository>(() => MyWorkoutRepository());

  // Регистрация BLoC (создаются каждый раз при запросе)
  locator.registerFactory(() => AuthBloc(locator<AuthService>()));
  // locator.registerFactory(() => WorkoutBloc(workoutRepository: locator<WorkoutRepository>()));
  locator.registerFactory(() => ExerciseBloc(exerciseRepository: locator<ExerciseRepository>()));
  locator.registerFactory(() => NutritionBloc(locator<NutritionRepository>()));
  locator.registerFactory(() => NotificationBloc(notificationService: locator<NotificationService>()));
}