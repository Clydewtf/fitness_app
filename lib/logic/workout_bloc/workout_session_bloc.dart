import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/utils.dart';
import '../../data/models/workout_session_model.dart';
import 'workout_session_event.dart';
import 'workout_session_state.dart';

class WorkoutSessionBloc extends Bloc<WorkoutSessionEvent, WorkoutSessionState> {
  Timer? _restTimer; // <-- сюда сохраним активный таймер

  WorkoutSessionBloc() : super(const WorkoutSessionState()) {
    on<StartWorkoutSession>(_onStartSession);
    on<StartExercise>(_onStartExercise);
    on<CompleteSet>(_onCompleteSet);
    on<CompleteExercise>(_onCompleteExercise);
    on<SkipExercise>(_onSkipExercise);
    on<FinishWorkoutSession>(_onFinishSession);
    on<RestTick>(_onRestTick);
    on<UpdateCurrentExerciseIndex>(_onUpdateCurrentExerciseIndex);
    on<ResetAutoAdvance>(_onResetAutoAdvance);
    on<AdvanceToIndex>(_onAdvanceToIndex);
  }

  @override
  Future<void> close() {
    _restTimer?.cancel();
    return super.close();
  }

  void _onResetAutoAdvance(ResetAutoAdvance event, Emitter emit) {
    emit(state.copyWith(shouldAutoAdvance: false));
  }

  void _onAdvanceToIndex(AdvanceToIndex event, Emitter emit) {
    emit(state.copyWith(
      currentExerciseIndex: event.index,
      shouldAutoAdvance: false,
      nextIndex: null,
    ));
  }

  void _onUpdateCurrentExerciseIndex(UpdateCurrentExerciseIndex event, Emitter emit) {
    emit(state.copyWith(currentExerciseIndex: event.index));
  }

  void _onStartSession(StartWorkoutSession event, Emitter emit) {
    final goal = event.goal;

    final progressList = event.workout.exercises
        .where((e) => e.modes.containsKey(goal)) // берём упражнения с нужной целью
        .map((e) => WorkoutExerciseProgress(
              exerciseId: e.exerciseId,
              workoutMode: e.modes[goal]!,
              status: ExerciseStatus.pending,
            ))
        .toList();

    final session = WorkoutSession(
      workoutId: event.workout.id,
      workoutName: event.workout.name,
      goal: goal,
      exercises: progressList,
      startTime: DateTime.now(),
    );

    emit(state.copyWith(session: session, currentExerciseIndex: 0));
  }

  void _onStartExercise(StartExercise event, Emitter emit) {
    final session = state.session!;
    final exercises = List<WorkoutExerciseProgress>.from(session.exercises);

    // Меняем статус выбранного упражнения на "inProgress"
    final updatedExercise = exercises[event.index].copyWith(
      status: ExerciseStatus.inProgress,
    );
    exercises[event.index] = updatedExercise;

    emit(state.copyWith(
      session: session.copyWith(exercises: exercises),
      currentExerciseIndex: event.index,
      currentSetIndex: 0, // начинаем с первого подхода
      isResting: false,
      //restTimer: null,
    ));
  }

  void _onCompleteSet(CompleteSet event, Emitter emit) {
    final session = state.session!;
    final exercises = List<WorkoutExerciseProgress>.from(session.exercises);
    final currentExercise = exercises[state.currentExerciseIndex];
    final setsRequired = currentExercise.workoutMode.sets;

    final nextSetIndex = state.currentSetIndex + 1;

    if (nextSetIndex >= setsRequired) {
      // Все подходы сделаны → завершить упражнение
      exercises[state.currentExerciseIndex] = currentExercise.copyWith(
        status: ExerciseStatus.done,
      );

      final nextIndex = findNextIncompleteExercise(exercises, state.currentExerciseIndex);

      if (nextIndex == null) {
        // Все упражнения завершены → завершить тренировку
        final finishedSession = session.copyWith(
          exercises: exercises,
          endTime: DateTime.now(),
        );
        emit(state.copyWith(
          session: finishedSession,
          isWorkoutFinished: true,
          currentSetIndex: 0,
          isResting: false,
          restSecondsLeft: null,
          shouldAutoAdvance: false,
          nextIndex: null,
        ));
      } else {
        // Переход к следующему упражнению
        emit(state.copyWith(
          session: session.copyWith(exercises: exercises),
          currentSetIndex: 0,
          isResting: false,
          restSecondsLeft: null,
          shouldAutoAdvance: true,
          nextIndex: nextIndex,
        ));
      }
    } else {
      emit(state.copyWith(
        currentSetIndex: nextSetIndex,
        isResting: true,
        restSecondsLeft: currentExercise.workoutMode.restSeconds,
        restDurationSeconds: currentExercise.workoutMode.restSeconds,
        restStartTime: DateTime.now(),
      ));

      Future.microtask(_startRestTimer);
    }
  }

  void _onCompleteExercise(CompleteExercise event, Emitter emit) {
    final session = state.session!;
    final exercises = List<WorkoutExerciseProgress>.from(session.exercises);

    exercises[event.index] = exercises[event.index].copyWith(
      status: ExerciseStatus.done,
    );

    final nextIndex = findNextIncompleteExercise(exercises, event.index);

    emit(state.copyWith(
      session: session.copyWith(exercises: exercises),
      //currentExerciseIndex: nextIndex ?? exercises.length,
      currentSetIndex: 0,
      isResting: false,
      restSecondsLeft: null,
      shouldAutoAdvance: nextIndex != null,
      nextIndex: nextIndex,
    ));
  }

  void _onSkipExercise(SkipExercise event, Emitter emit) {
    final session = state.session!;
    final exercises = List<WorkoutExerciseProgress>.from(session.exercises);

    // Обновляем статус упражнения на skipped
    exercises[event.index] = exercises[event.index].copyWith(
      status: ExerciseStatus.skipped,
    );

    // Пытаемся найти следующее упражнение
    final nextIndex = findNextIncompleteExercise(exercises, event.index);

    // Проверяем, все ли упражнения скипнуты
    final allSkipped = exercises.every((e) => e.status == ExerciseStatus.skipped);
    final hasAnyCompleted = exercises.any((e) => e.status == ExerciseStatus.done);

    if (nextIndex == null) {
      if (allSkipped) {
        final updatedSession = session.copyWith(
          exercises: exercises,
        );

        // ВАЖНО: сначала применить session с новыми упражнениями, потом его обнулить
        emit(state.copyWith(
          session: updatedSession,
        ));

        // Все упражнения были скипнуты → просто сбрасываем сессию
        emit(state.copyWith(
          session: null,
          nextIndex: null,
          currentSetIndex: 0,
          isResting: false,
          restSecondsLeft: null,
          shouldAutoAdvance: false,
          isWorkoutFinished: false,
          isWorkoutAborted: true,
        ));
        return;
      } else if (hasAnyCompleted) {
        // Некоторые упражнения завершены → завершаем тренировку
        final finishedSession = session.copyWith(
          exercises: exercises,
          endTime: DateTime.now(),
        );
        emit(state.copyWith(
          session: finishedSession,
          isWorkoutFinished: true,
          currentSetIndex: 0,
          isResting: false,
          restSecondsLeft: null,
          shouldAutoAdvance: false,
          nextIndex: null,
        ));
      }
      return;
    }

    // Есть следующее упражнение — просто двигаемся к нему
    emit(state.copyWith(
      session: session.copyWith(exercises: exercises),
      currentSetIndex: 0,
      isResting: false,
      restSecondsLeft: null,
      shouldAutoAdvance: true,
      nextIndex: nextIndex,
    ));
  }

  // void _onSkipExercise(SkipExercise event, Emitter emit) {
  //   final session = state.session!;
  //   final exercises = List<WorkoutExerciseProgress>.from(session.exercises);

  //   exercises[event.index] = exercises[event.index].copyWith(
  //     status: ExerciseStatus.skipped,
  //   );

  //   final nextIndex = findNextIncompleteExercise(exercises, event.index);

  //   emit(state.copyWith(
  //     session: session.copyWith(exercises: exercises),
  //     //currentExerciseIndex: nextIndex ?? exercises.length,
  //     currentSetIndex: 0,
  //     isResting: false,
  //     restSecondsLeft: null,
  //     shouldAutoAdvance: nextIndex != null,
  //     nextIndex: nextIndex,
  //   ));
  // }

  void _onFinishSession(FinishWorkoutSession event, Emitter emit) {
    final session = state.session!;
    session.endTime = DateTime.now();
    emit(state.copyWith(session: session, isWorkoutFinished: true));
  }

  void _startRestTimer() {
    _restTimer?.cancel();

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      add(RestTick());
    });
  }

  void _onRestTick(RestTick event, Emitter emit) {
    final startTime = state.restStartTime;
    final duration = state.restDurationSeconds;

    if (startTime == null || duration == null) return;

    final secondsPassed = DateTime.now().difference(startTime).inSeconds;
    final secondsLeft = duration - secondsPassed;

    if (secondsLeft <= 0) {
      _restTimer?.cancel();
      emit(state.copyWith(
        isResting: false,
        restSecondsLeft: null,
        restStartTime: null,
      ));
    } else {
      emit(state.copyWith(
        restSecondsLeft: secondsLeft,
      ));
    }
  }

  // void _onRestTick(RestTick event, Emitter emit) {
  //   if (state.restSecondsLeft == null) return;

  //   final secondsLeft = state.restSecondsLeft! - 1;

  //   if (secondsLeft <= 0) {
  //     _restTimer?.cancel();
  //     emit(state.copyWith(
  //       isResting: false,
  //       restSecondsLeft: null,
  //     ));
  //   } else {
  //     emit(state.copyWith(
  //       restSecondsLeft: secondsLeft,
  //     ));
  //   }
  // }
}