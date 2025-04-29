import '../../data/models/workout_model.dart';

abstract class WorkoutSessionEvent {}

class StartWorkoutSession extends WorkoutSessionEvent {
  final Workout workout;
  final String goal;
  StartWorkoutSession(this.workout, this.goal);
}

class StartExercise extends WorkoutSessionEvent {
  final int index;
  StartExercise(this.index);
}

class CompleteSet extends WorkoutSessionEvent {}

class CompleteExercise extends WorkoutSessionEvent {
  final int index;
  CompleteExercise(this.index);
}

class SkipExercise extends WorkoutSessionEvent {
  final int index;
  SkipExercise(this.index);
}

class FinishWorkoutSession extends WorkoutSessionEvent {}

class RestTick extends WorkoutSessionEvent {}

class UpdateCurrentExerciseIndex extends WorkoutSessionEvent {
  final int index;
  UpdateCurrentExerciseIndex(this.index);
}

class ResetAutoAdvance extends WorkoutSessionEvent {}

class AdvanceToIndex extends WorkoutSessionEvent {
  final int index;
  AdvanceToIndex(this.index);
}