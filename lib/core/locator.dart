import 'package:get_it/get_it.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../data/repositories/workout_repository.dart';
import '../data/repositories/nutrition_repository.dart';
import '../logic/auth_bloc/auth_bloc.dart';
import '../logic/workout_bloc/workout_bloc.dart';
import '../logic/nutrition_bloc/nutrition_bloc.dart';
import '../logic/notification_bloc/notification_bloc.dart';

final GetIt locator = GetIt.instance;

void setupLocator() {
  // Регистрация сервисов
  locator.registerLazySingleton<AuthService>(() => AuthService());
  locator.registerLazySingleton<UserService>(() => UserService());

  // Регистрация репозиториев (синглтоны)
  locator.registerLazySingleton<WorkoutRepository>(() => WorkoutRepository());
  locator.registerLazySingleton<NutritionRepository>(() => NutritionRepository());

  // Регистрация BLoC (создаются каждый раз при запросе)
  locator.registerFactory(() => AuthBloc(locator<AuthService>()));
  locator.registerFactory(() => WorkoutBloc(locator<WorkoutRepository>()));
  locator.registerFactory(() => NutritionBloc(locator<NutritionRepository>()));
  locator.registerFactory(() => NotificationBloc());
}