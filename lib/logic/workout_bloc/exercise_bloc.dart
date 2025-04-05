import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/exercise_model.dart';
import 'exercise_event.dart';
import 'exercise_state.dart';
import '../../data/repositories/workout_repository.dart';

class ExerciseBloc extends Bloc<ExerciseEvent, ExerciseState> {
  final WorkoutRepository workoutRepository;
  List<Exercise> _allExercises = [];

  ExerciseBloc({required this.workoutRepository}) : super(ExerciseInitial()) {
    on<LoadExercises>(_onLoadExercises);
    on<FilterExercises>(_onFilterExercises);
  }

  Future<void> _onLoadExercises(LoadExercises event, Emitter<ExerciseState> emit) async {
    emit(ExerciseLoading());
    try {
      final exercises = await workoutRepository.getAllExercises();
      emit(ExerciseLoaded(exercises, exercises));
    } catch (e) {
      emit(ExerciseError('Ошибка загрузки упражнений'));
    }
  }

  void _onFilterExercises(FilterExercises event, Emitter<ExerciseState> emit) {
    final currentState = state;
    if (currentState is ExerciseLoaded) { 
      final all = currentState.allExercises;

      final filtered = all.where((exercise) {
        final matchMuscle = event.muscleGroup == null || exercise.muscleGroup == event.muscleGroup;
        final matchType = event.type == null || exercise.type == event.type;
        final matchEquipment = event.equipment == null || exercise.equipment == event.equipment;
        final matchSearch = event.searchQuery == null ||
          event.searchQuery!.isEmpty ||
          exercise.name.toLowerCase().contains(event.searchQuery!.toLowerCase());
        return matchMuscle && matchType && matchEquipment && matchSearch;
      }).toList();

      emit(ExerciseLoaded(all, filtered));
    }
  }
}