import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/user_service.dart';
import 'workout_event.dart';
import 'workout_state.dart';
import '../../data/repositories/workout_repository.dart';

class WorkoutBloc extends Bloc<WorkoutEvent, WorkoutState> {
  final WorkoutRepository workoutRepository;
  final UserService userService;
  final String uid;

  WorkoutBloc({
    required this.workoutRepository,
    required this.userService,
    required this.uid,
  }) : super(WorkoutInitial()) {
    on<LoadWorkouts>(_onLoadWorkouts);
    on<ToggleFavoriteWorkout>(_onToggleFavorite);
  }

  Future<void> _onLoadWorkouts(LoadWorkouts event, Emitter<WorkoutState> emit) async {
    emit(WorkoutLoading());
    try {
      final workouts = await workoutRepository.fetchWorkouts();
      final favoriteIds = await userService.getFavoriteWorkouts(uid);

      final updatedWorkouts = workouts.map((w) {
        final isFav = favoriteIds.contains(w.id);
        return w.copyWith(isFavorite: isFav);
      }).toList();

      emit(WorkoutLoaded(updatedWorkouts, favoriteIds));
    } catch (e) {
      emit(WorkoutError("Не удалось загрузить тренировки"));
    }
  }

  Future<void> _onToggleFavorite(ToggleFavoriteWorkout event, Emitter<WorkoutState> emit) async {
    final currentState = state;
    if (currentState is WorkoutLoaded) {
      try {
        // Обновляем в UserService (список избранного для пользователя)
        if (event.isFavorite) {
          await userService.addFavoriteWorkout(uid, event.workoutId);
        } else {
          await userService.removeFavoriteWorkout(uid, event.workoutId);
        }
        
        // Обновляем список избранных ID
        final updatedFavorites = List<String>.from(currentState.favoriteWorkoutIds);
        if (event.isFavorite) {
          updatedFavorites.add(event.workoutId);
        } else {
          updatedFavorites.remove(event.workoutId);
        }

        // Обновляем список тренировок — только нужную
        final updatedWorkouts = currentState.workouts.map((workout) {
          if (workout.id == event.workoutId) {
            return workout.copyWith(isFavorite: event.isFavorite);
          }
          return workout;
        }).toList();

        emit(WorkoutLoaded(updatedWorkouts, updatedFavorites));
      } catch (e) {
        emit(WorkoutError("Ошибка при обновлении избранного"));
      }
    }
  }
}