import 'package:flutter_bloc/flutter_bloc.dart';
import 'workout_event.dart';
import 'workout_state.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/models/workout_model.dart';

class WorkoutBloc extends Bloc<WorkoutEvent, WorkoutState> {
  final WorkoutRepository workoutRepository;

  WorkoutBloc(this.workoutRepository) : super(WorkoutInitial());
}