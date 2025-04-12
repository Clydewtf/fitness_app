import 'package:equatable/equatable.dart';
import '../../data/models/workout_model.dart';

abstract class WorkoutState extends Equatable {
  @override
  List<Object?> get props => [];
}

class WorkoutInitial extends WorkoutState {}

class WorkoutLoading extends WorkoutState {}

class WorkoutLoaded extends WorkoutState {
  final List<Workout> workouts;
  final List<String> favoriteWorkoutIds;

  WorkoutLoaded(this.workouts, this.favoriteWorkoutIds);

  @override
  List<Object?> get props => [workouts, favoriteWorkoutIds];
}

class WorkoutError extends WorkoutState {
  final String message;

  WorkoutError(this.message);

  @override
  List<Object?> get props => [message];
}