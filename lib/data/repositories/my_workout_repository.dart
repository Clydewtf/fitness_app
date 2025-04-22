import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/workout_model.dart';

class MyWorkoutRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Workout>> fetchMyWorkouts(String uid) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('my_workouts')
        .get();

    return snapshot.docs
        .map((doc) => Workout.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<void> addWorkout(String uid, Workout workout) async {
    final docRef = _firestore
      .collection('users')
      .doc(uid)
      .collection('my_workouts')
      .doc();
    
    final workoutWithId = workout.copyWith(id: docRef.id);

    await docRef.set(workoutWithId.toMap());
  }

  Future<void> updateWorkout(String uid, String workoutId, Workout updatedWorkout) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('my_workouts')
        .doc(workoutId)
        .update(updatedWorkout.toMap());
  }

  Future<void> deleteWorkout(String uid, String workoutId) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('my_workouts')
        .doc(workoutId)
        .delete();
  }

  Future<void> updateFavoriteStatus(String uid, String workoutId, bool isFavorite) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('my_workouts')
        .doc(workoutId)
        .update({'isFavorite': isFavorite});
  }
}