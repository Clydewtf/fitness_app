import 'package:equatable/equatable.dart';

abstract class ExerciseEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadExercises extends ExerciseEvent {}

class FilterExercises extends ExerciseEvent {
  final String? muscleGroup;
  final String? type;
  final String? equipment;
  final List<String>? levels;
  final String? searchQuery;

  FilterExercises({this.muscleGroup, this.type, this.equipment, this.levels, this.searchQuery});

  @override
  List<Object?> get props => [muscleGroup, type, equipment, levels, searchQuery];
}