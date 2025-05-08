import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/exercise_model.dart';

class ExerciseRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Exercise>> fetchExercises() async {
    final snapshot = await _firestore.collection('exercises').get();
    return snapshot.docs
        .map((doc) => Exercise.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<Exercise?> getExerciseById(String id) async {
    try {
      final doc = await _firestore.collection('exercises').doc(id).get();
      if (doc.exists) {
        return Exercise.fromMap(doc.data()!, doc.id);
      }
    } catch (e) {
      if (kDebugMode) {
        print("Ошибка при загрузке упражнения $id: $e");
      }
    }
    return null;
  }

  Future<List<Exercise>> getExercisesByIds(List<String> ids) async {
    final List<Exercise> exercises = [];

    try {
      // Firestore ограничивает whereIn до 10 элементов — разобьём, если надо
      const batchSize = 10;
      for (var i = 0; i < ids.length; i += batchSize) {
        final batchIds = ids.sublist(i, i + batchSize > ids.length ? ids.length : i + batchSize);

        final querySnapshot = await _firestore
            .collection('exercises')
            .where(FieldPath.documentId, whereIn: batchIds)
            .get();

        for (final doc in querySnapshot.docs) {
          try {
            exercises.add(Exercise.fromMap(doc.data(), doc.id));
          } catch (e) {
            if (kDebugMode) {
              print("Ошибка при парсинге упражнения ${doc.id}: $e");
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Ошибка при загрузке упражнений: $e");
      }
    }

    return exercises;
  }
}