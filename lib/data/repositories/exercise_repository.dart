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
      print("Ошибка при загрузке упражнения $id: $e");
    }
    return null;
  }
}