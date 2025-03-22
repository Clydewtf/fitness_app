import 'package:flutter_bloc/flutter_bloc.dart';
import 'workout_event.dart';
import 'workout_state.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/models/workout_model.dart';

class WorkoutBloc extends Bloc<WorkoutEvent, WorkoutState> {
  final WorkoutRepository workoutRepository;

  WorkoutBloc(this.workoutRepository) : super(WorkoutInitial()) {
    on<LoadWorkouts>(_onLoadWorkouts);
    on<AddWorkout>(_onAddWorkout);
    on<DeleteWorkout>(_onDeleteWorkout);
  }

  // Загрузка списка тренировок
  Future<void> _onLoadWorkouts(LoadWorkouts event, Emitter<WorkoutState> emit) async {
    try {
      final workouts = await workoutRepository.loadWorkouts();
      emit(WorkoutsLoaded(workouts));
    } catch (e) {
      emit(WorkoutError("Ошибка загрузки тренировок"));
    }
  }

  // Добавление новой тренировки
  Future<void> _onAddWorkout(AddWorkout event, Emitter<WorkoutState> emit) async {
    try {
      final currentState = state;
      if (currentState is WorkoutsLoaded) {
        final updatedWorkouts = List<WorkoutModel>.from(currentState.workouts)..add(event.workout);
        await workoutRepository.saveWorkouts(updatedWorkouts);
        emit(WorkoutsLoaded(updatedWorkouts));
      }
    } catch (e) {
      emit(WorkoutError("Ошибка добавления тренировки"));
    }
  }

  // Удаление тренировки
  Future<void> _onDeleteWorkout(DeleteWorkout event, Emitter<WorkoutState> emit) async {
    try {
      final currentState = state;
      if (currentState is WorkoutsLoaded) {
        final updatedWorkouts =
            currentState.workouts.where((w) => w.id != event.workoutId).toList();
        await workoutRepository.saveWorkouts(updatedWorkouts);
        emit(WorkoutsLoaded(updatedWorkouts));
      }
    } catch (e) {
      emit(WorkoutError("Ошибка удаления тренировки"));
    }
  }
}