import 'package:equatable/equatable.dart';
import '../../data/models/nutrition_model.dart';

abstract class NutritionEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

// Загрузка записей о питании
class LoadNutritionEntries extends NutritionEvent {}

// Добавление новой записи о питании
class AddNutritionEntry extends NutritionEvent {
  final NutritionEntry entry;

  AddNutritionEntry(this.entry);

  @override
  List<Object?> get props => [entry];
}

// Удаление записи о питании
class DeleteNutritionEntry extends NutritionEvent {
  final String entryId;

  DeleteNutritionEntry(this.entryId);

  @override
  List<Object?> get props => [entryId];
}