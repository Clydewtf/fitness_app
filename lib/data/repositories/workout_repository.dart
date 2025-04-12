import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/workout_model.dart';

class WorkoutRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Workout>> fetchWorkouts() async {
    final snapshot = await _firestore.collection('workouts').get();
    return snapshot.docs
        .map((doc) => Workout.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<void> updateFavorite(String workoutId, bool isFavorite) async {
    await _firestore.collection('workouts').doc(workoutId).update({
      'isFavorite': isFavorite,
    });
  }

  Future<void> addWorkout(Workout workout) async {
    await _firestore.collection('workouts').add(workout.toMap());
  }

  Future<void> deleteWorkout(String workoutId) async {
    await _firestore.collection('workouts').doc(workoutId).delete();
  }
}