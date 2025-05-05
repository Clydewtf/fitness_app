import 'workout_model.dart';

class WorkoutSession {
  final String workoutId;
  final String workoutName;
  final String goal;
  final List<WorkoutExerciseProgress> exercises;
  final DateTime startTime;
  DateTime? endTime;

  WorkoutSession({
    required this.workoutId,
    required this.workoutName,
    required this.goal,
    required this.exercises,
    required this.startTime,
    this.endTime,
  });

  bool get isCompleted => exercises.every((e) => e.status == ExerciseStatus.done);
}

enum ExerciseStatus { pending, inProgress, done, skipped }

class WorkoutExerciseProgress {
  final String exerciseId;
  final WorkoutMode workoutMode;
  ExerciseStatus status;
  Duration? timeSpent;

  WorkoutExerciseProgress({
    required this.exerciseId,
    required this.workoutMode,
    this.status = ExerciseStatus.pending,
    this.timeSpent,
  });
}

extension WorkoutSessionCopyWith on WorkoutSession {
  WorkoutSession copyWith({
    String? workoutId,
    String? workoutName,
    String? goal,
    List<WorkoutExerciseProgress>? exercises,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return WorkoutSession(
      workoutId: workoutId ?? this.workoutId,
      workoutName: workoutName ?? this.workoutName,
      goal: goal ?? this.goal,
      exercises: exercises ?? this.exercises,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}

extension WorkoutExerciseProgressCopyWith on WorkoutExerciseProgress {
  WorkoutExerciseProgress copyWith({
    String? exerciseId,
    WorkoutMode? workoutMode,
    ExerciseStatus? status,
    Duration? timeSpent,
  }) {
    return WorkoutExerciseProgress(
      exerciseId: exerciseId ?? this.exerciseId,
      workoutMode: workoutMode ?? this.workoutMode,
      status: status ?? this.status,
      timeSpent: timeSpent ?? this.timeSpent,
    );
  }
}