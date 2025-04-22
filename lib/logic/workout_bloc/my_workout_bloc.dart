import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/my_workout_repository.dart';
import '../../services/user_service.dart';
import '../workout_bloc/my_workout_event.dart';
import '../workout_bloc/my_workout_state.dart';

class MyWorkoutBloc extends Bloc<MyWorkoutEvent, MyWorkoutState> {
  final MyWorkoutRepository repository;
  final userService = UserService();

  MyWorkoutBloc(this.repository) : super(MyWorkoutInitial()) {
    on<LoadMyWorkouts>((event, emit) async {
      emit(MyWorkoutLoading());
      try {
        final workouts = await repository.fetchMyWorkouts(event.uid);
        final favorites = await userService.getFavoriteWorkouts(event.uid);
        emit(MyWorkoutLoaded(workouts, favorites));
      } catch (e) {
        emit(MyWorkoutError(e.toString()));
      }
    });

    on<AddMyWorkout>((event, emit) async {
      try {
        await repository.addWorkout(event.uid, event.workout);
        final workouts = await repository.fetchMyWorkouts(event.uid);
        final favorites = await userService.getFavoriteWorkouts(event.uid);
        emit(MyWorkoutLoaded(workouts, favorites));
      } catch (e) {
        emit(MyWorkoutError(e.toString()));
      }
    });

    on<UpdateMyWorkout>((event, emit) async {
      try {
        await repository.updateWorkout(event.uid, event.workout.id, event.workout);
        final workouts = await repository.fetchMyWorkouts(event.uid);
        final favorites = await userService.getFavoriteWorkouts(event.uid);
        emit(MyWorkoutLoaded(workouts, favorites));
      } catch (e) {
        emit(MyWorkoutError(e.toString()));
      }
    });

    on<DeleteMyWorkout>((event, emit) async {
      try {
        await repository.deleteWorkout(event.uid, event.workoutId);
        final workouts = await repository.fetchMyWorkouts(event.uid);
        final favorites = await userService.getFavoriteWorkouts(event.uid);
        emit(MyWorkoutLoaded(workouts, favorites));
      } catch (e) {
        emit(MyWorkoutError(e.toString()));
      }
    });

    on<ToggleFavoriteMyWorkout>((event, emit) async {
      final currentState = state;
      if (currentState is MyWorkoutLoaded) {
        try {
          // Обновляем избранное в userService
          if (event.isFavorite) {
            await userService.addFavoriteWorkout(event.uid, event.workoutId);
          } else {
            await userService.removeFavoriteWorkout(event.uid, event.workoutId);
          }

          // Обновляем isFavorite в my_workouts
          await repository.updateFavoriteStatus(event.uid, event.workoutId, event.isFavorite);
          
          // Обновляем состояние
          final updatedWorkouts = currentState.workouts.map((workout) {
            if (workout.id == event.workoutId) {
              return workout.copyWith(isFavorite: event.isFavorite);
            }
            return workout;
          }).toList();

          final favorites = await userService.getFavoriteWorkouts(event.uid);

          emit(MyWorkoutLoaded(updatedWorkouts, favorites));
        } catch (e) {
          emit(MyWorkoutError(e.toString()));
        }
      }
    });
  }
}