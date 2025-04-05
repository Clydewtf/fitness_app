import 'package:shared_preferences/shared_preferences.dart';
import '../models/exercise_model.dart';
import 'dart:convert';

class WorkoutRepository {
  // Пока что заглушка — потом заменим на загрузку из Firebase или локального хранилища
  Future<List<Exercise>> getAllExercises() async {
    await Future.delayed(const Duration(milliseconds: 500)); // эмуляция загрузки

    return [
      Exercise(
        id: '1',
        name: 'Жим лежа',
        muscleGroup: 'Грудь',
        type: 'Силовая',
        equipment: 'Штанга',
        description: 'Классическое упражнение на грудные мышцы.',
        imageUrl: null,
      ),
      Exercise(
        id: '2',
        name: 'Приседания',
        muscleGroup: 'Ноги',
        type: 'Силовая',
        equipment: 'Вес тела',
        description: 'Базовое упражнение на ноги и ягодицы.',
        imageUrl: null,
      ),
      Exercise(
        id: '3',
        name: 'Планка',
        muscleGroup: 'Пресс',
        type: 'Статическая',
        equipment: 'Без оборудования',
        description: 'Удержание тела в горизонтальном положении.',
        imageUrl: null,
      ),
    ];
  }
}