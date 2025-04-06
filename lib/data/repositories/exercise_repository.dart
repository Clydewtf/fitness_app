import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exercise_model.dart';

class ExerciseRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Exercise>> fetchExercises() async {
    final snapshot = await _firestore.collection('exercises').get();
    return snapshot.docs
        .map((doc) => Exercise.fromMap(doc.data(), doc.id))
        .toList();
  }
}
