import 'package:equatable/equatable.dart';
import '../../data/models/nutrition_model.dart';

abstract class NutritionState extends Equatable {
  @override
  List<Object?> get props => [];
}

// Начальное состояние
class NutritionInitial extends NutritionState {}

// Записи питания загружены
class NutritionLoaded extends NutritionState {
  final List<NutritionEntry> entries;

  NutritionLoaded(this.entries);

  @override
  List<Object?> get props => [entries];
}

// Ошибка при загрузке записей
class NutritionError extends NutritionState {
  final String message;

  NutritionError(this.message);

  @override
  List<Object?> get props => [message];
}