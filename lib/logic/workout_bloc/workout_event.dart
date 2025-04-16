import 'package:equatable/equatable.dart';

abstract class WorkoutEvent extends Equatable {
  const WorkoutEvent();

  @override
  List<Object?> get props => [];
}

class LoadWorkouts extends WorkoutEvent {}

class ToggleFavoriteWorkout extends WorkoutEvent {
  final String workoutId;
  final bool isFavorite;

  const ToggleFavoriteWorkout({
    required this.workoutId,
    required this.isFavorite,
  });

  @override
  List<Object?> get props => [workoutId, isFavorite];
}

class LoadMyWorkouts extends WorkoutEvent {
  final String uid;
  const LoadMyWorkouts(this.uid);
}