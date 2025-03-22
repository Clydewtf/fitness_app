import 'package:flutter_bloc/flutter_bloc.dart';
import 'nutrition_event.dart';
import 'nutrition_state.dart';
import '../../data/repositories/nutrition_repository.dart';
import '../../data/models/nutrition_model.dart';

class NutritionBloc extends Bloc<NutritionEvent, NutritionState> {
  final NutritionRepository nutritionRepository;

  NutritionBloc(this.nutritionRepository) : super(NutritionInitial()) {
    on<LoadNutritionEntries>(_onLoadEntries);
    on<AddNutritionEntry>(_onAddEntry);
    on<DeleteNutritionEntry>(_onDeleteEntry);
  }

  // Загрузка записей о питании
  Future<void> _onLoadEntries(LoadNutritionEntries event, Emitter<NutritionState> emit) async {
    try {
      final entries = await nutritionRepository.loadNutritionEntries();
      emit(NutritionLoaded(entries));
    } catch (e) {
      emit(NutritionError("Ошибка загрузки данных о питании"));
    }
  }

  // Добавление новой записи
  Future<void> _onAddEntry(AddNutritionEntry event, Emitter<NutritionState> emit) async {
    try {
      final currentState = state;
      if (currentState is NutritionLoaded) {
        final updatedEntries = List<NutritionEntry>.from(currentState.entries)..add(event.entry);
        await nutritionRepository.saveNutritionEntries(updatedEntries);
        emit(NutritionLoaded(updatedEntries));
      }
    } catch (e) {
      emit(NutritionError("Ошибка добавления записи о питании"));
    }
  }

  // Удаление записи
  Future<void> _onDeleteEntry(DeleteNutritionEntry event, Emitter<NutritionState> emit) async {
    try {
      final currentState = state;
      if (currentState is NutritionLoaded) {
        final updatedEntries =
            currentState.entries.where((entry) => entry.id != event.entryId).toList();
        await nutritionRepository.saveNutritionEntries(updatedEntries);
        emit(NutritionLoaded(updatedEntries));
      }
    } catch (e) {
      emit(NutritionError("Ошибка удаления записи о питании"));
    }
  }
}