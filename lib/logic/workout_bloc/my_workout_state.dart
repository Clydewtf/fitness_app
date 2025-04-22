import '../../data/models/workout_model.dart';

abstract class MyWorkoutState {}

class MyWorkoutInitial extends MyWorkoutState {}

class MyWorkoutLoading extends MyWorkoutState {}

class MyWorkoutLoaded extends MyWorkoutState {
  final List<Workout> workouts;
  final List<String> favoriteWorkoutIds;
  MyWorkoutLoaded(this.workouts, this.favoriteWorkoutIds);
}

class MyWorkoutError extends MyWorkoutState {
  final String message;
  MyWorkoutError(this.message);
}