import 'package:equatable/equatable.dart';
import '../../data/models/exercise_model.dart';

abstract class ExerciseState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ExerciseInitial extends ExerciseState {}

class ExerciseLoading extends ExerciseState {}

class ExerciseLoaded extends ExerciseState {
  final List<Exercise> allExercises;
  final List<Exercise> filteredExercises;

  ExerciseLoaded(this.allExercises, this.filteredExercises);

  @override
  List<Object?> get props => [allExercises, filteredExercises];
}

class ExerciseError extends ExerciseState {
  final String message;

  ExerciseError(this.message);

  @override
  List<Object?> get props => [message];
}

class ExerciseFiltered extends ExerciseState {
  final List<Exercise> filteredExercises;

  ExerciseFiltered(this.filteredExercises);

  @override
  List<Object?> get props => [filteredExercises];
}