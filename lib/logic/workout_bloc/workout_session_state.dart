import '../../data/models/exercise_model.dart';
import '../../data/models/workout_session_model.dart';

class WorkoutSessionState {
  final WorkoutSession? session;
  final Map<String, Exercise> exercisesById;
  final int currentExerciseIndex;
  final int currentSetIndex; // индекс подхода (0 = первый)
  final bool isResting;
  final int? restSecondsLeft;
  final int? restDurationSeconds;
  final DateTime? restStartTime;
  final bool shouldAutoAdvance;
  final int? nextIndex;
  final bool isWorkoutFinished;
  final bool isWorkoutAborted;
  //final Duration? restTimer; // оставшееся время отдыха (если есть)

  bool get isActive => session != null;

  const WorkoutSessionState({
    this.session,
    this.exercisesById = const {},
    this.currentExerciseIndex = 0,
    this.currentSetIndex = 0,
    this.isResting = false,
    this.restSecondsLeft,
    this.restDurationSeconds,
    this.restStartTime,
    this.shouldAutoAdvance = false,
    this.nextIndex,
    this.isWorkoutFinished = false,
    this.isWorkoutAborted = false,
    //this.restTimer,
  });

  WorkoutSessionState copyWith({
    WorkoutSession? session,
    Map<String, Exercise>? exercisesById,
    int? currentExerciseIndex,
    int? currentSetIndex,
    bool? isResting,
    int? restSecondsLeft,
    int? restDurationSeconds,
    DateTime? restStartTime,
    bool? shouldAutoAdvance,
    int? nextIndex,
    bool? isWorkoutFinished,
    bool? isWorkoutAborted,
    //Duration? restTimer,
  }) {
    return WorkoutSessionState(
      session: session ?? this.session,
      exercisesById: exercisesById ?? this.exercisesById,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      currentSetIndex: currentSetIndex ?? this.currentSetIndex,
      isResting: isResting ?? this.isResting,
      restSecondsLeft: restSecondsLeft ?? this.restSecondsLeft,
      restDurationSeconds: restDurationSeconds ?? this.restDurationSeconds,
      restStartTime: restStartTime ?? this.restStartTime,
      shouldAutoAdvance: shouldAutoAdvance ?? this.shouldAutoAdvance,
      nextIndex: nextIndex ?? this.nextIndex,
      isWorkoutFinished: isWorkoutFinished ?? this.isWorkoutFinished,
      isWorkoutAborted: isWorkoutAborted ?? this.isWorkoutAborted,
      //restTimer: restTimer ?? this.restTimer,
    );
  }

  WorkoutExerciseProgress? get currentExercise {
    if (session == null) return null;
    if (currentExerciseIndex < 0 || currentExerciseIndex >= session!.exercises.length) return null;
    return session!.exercises[currentExerciseIndex];
  }
}