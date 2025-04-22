import '../../data/models/workout_model.dart';

abstract class MyWorkoutEvent {}

class LoadMyWorkouts extends MyWorkoutEvent {
  final String uid;
  LoadMyWorkouts(this.uid);
}

class AddMyWorkout extends MyWorkoutEvent {
  final String uid;
  final Workout workout;
  AddMyWorkout(this.uid, this.workout);
}

class UpdateMyWorkout extends MyWorkoutEvent {
  final String uid;
  final Workout workout;
  UpdateMyWorkout(this.uid, this.workout);
}

class DeleteMyWorkout extends MyWorkoutEvent {
  final String uid;
  final String workoutId;
  DeleteMyWorkout(this.uid, this.workoutId);
}

class ToggleFavoriteMyWorkout extends MyWorkoutEvent {
  final String uid;
  final String workoutId;
  final bool isFavorite;

  ToggleFavoriteMyWorkout({
    required this.uid,
    required this.workoutId,
    required this.isFavorite,
  });
}