import 'package:equatable/equatable.dart';
import '../../data/models/workout_model.dart';

abstract class WorkoutState extends Equatable {
  @override
  List<Object?> get props => [];
}

// Начальное состояние
class WorkoutInitial extends WorkoutState {}

// Список тренировок загружен
class WorkoutsLoaded extends WorkoutState {
  final List<WorkoutModel> workouts;

  WorkoutsLoaded(this.workouts);

  @override
  List<Object?> get props => [workouts];
}

// Ошибка при загрузке тренировок
class WorkoutError extends WorkoutState {
  final String message;

  WorkoutError(this.message);

  @override
  List<Object?> get props => [message];
}