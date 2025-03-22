import 'package:equatable/equatable.dart';
import '../../data/models/workout_model.dart';

abstract class WorkoutEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

// Загрузка списка тренировок
class LoadWorkouts extends WorkoutEvent {}

// Добавление новой тренировки
class AddWorkout extends WorkoutEvent {
  final WorkoutModel workout;

  AddWorkout(this.workout);

  @override
  List<Object?> get props => [workout];
}

// Удаление тренировки
class DeleteWorkout extends WorkoutEvent {
  final String workoutId;

  DeleteWorkout(this.workoutId);

  @override
  List<Object?> get props => [workoutId];
}