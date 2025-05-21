import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/workout_log_model.dart';
import '../../data/repositories/workout_log_repository.dart';

class WorkoutLogState {
  final List<WorkoutLog> logs;
  final bool isLoading;

  WorkoutLogState({required this.logs, this.isLoading = false});

  WorkoutLogState copyWith({List<WorkoutLog>? logs, bool? isLoading}) {
    return WorkoutLogState(
      logs: logs ?? this.logs,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class WorkoutLogCubit extends Cubit<WorkoutLogState> {
  final WorkoutLogRepository repository;
  final String userId;

  WorkoutLogCubit({required this.repository, required this.userId})
      : super(WorkoutLogState(logs: []));

  Future<void> loadLogs() async {
    emit(state.copyWith(isLoading: true));
    final logs = await repository.getWorkoutLogs(userId);
    emit(state.copyWith(logs: logs, isLoading: false));
  }

  void updateLog(WorkoutLog updatedLog) {
    final updatedLogs = state.logs.map((log) {
      return log.id == updatedLog.id ? updatedLog : log;
    }).toList();

    emit(state.copyWith(logs: updatedLogs));
  }
}