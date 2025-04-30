import '../../data/models/workout_session_model.dart';

class WorkoutSessionState {
  final WorkoutSession? session;
  final int currentExerciseIndex;
  final int currentSetIndex; // индекс подхода (0 = первый)
  final bool isResting; // идет ли сейчас отдых
  final int? restSecondsLeft;
  final int? restDurationSeconds;
  final DateTime? restStartTime;
  final bool shouldAutoAdvance;
  final int? nextIndex;
  //final Duration? restTimer; // оставшееся время отдыха (если есть)

  bool get isActive => session != null;

  const WorkoutSessionState({
    this.session,
    this.currentExerciseIndex = 0,
    this.currentSetIndex = 0,
    this.isResting = false,
    this.restSecondsLeft,
    this.restDurationSeconds,
    this.restStartTime,
    this.shouldAutoAdvance = false,
    this.nextIndex,
    //this.restTimer,
  });

  WorkoutSessionState copyWith({
    WorkoutSession? session,
    int? currentExerciseIndex,
    int? currentSetIndex,
    bool? isResting,
    int? restSecondsLeft,
    int? restDurationSeconds,
    DateTime? restStartTime,
    bool? shouldAutoAdvance,
    int? nextIndex,
    //Duration? restTimer,
  }) {
    return WorkoutSessionState(
      session: session ?? this.session,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      currentSetIndex: currentSetIndex ?? this.currentSetIndex,
      isResting: isResting ?? this.isResting,
      restSecondsLeft: restSecondsLeft ?? this.restSecondsLeft,
      restDurationSeconds: restDurationSeconds ?? this.restDurationSeconds,
      restStartTime: restStartTime ?? this.restStartTime,
      shouldAutoAdvance: shouldAutoAdvance ?? this.shouldAutoAdvance,
      nextIndex: nextIndex ?? this.nextIndex,
      //restTimer: restTimer ?? this.restTimer,
    );
  }

  WorkoutExerciseProgress? get currentExercise {
    if (session == null) return null;
    if (currentExerciseIndex < 0 || currentExerciseIndex >= session!.exercises.length) return null;
    return session!.exercises[currentExerciseIndex];
  }
}