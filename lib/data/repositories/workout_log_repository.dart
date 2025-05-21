import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/workout_log_model.dart';

class WorkoutLogRepository {
  final FirebaseFirestore _firestore;

  WorkoutLogRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> saveWorkoutLog(WorkoutLog log) async {
    final docRef = _firestore
        .collection('users')
        .doc(log.userId)
        .collection('workoutLogs')
        .doc(log.id);

    await docRef.set(log.toMap());
  }

  Future<List<WorkoutLog>> getWorkoutLogs(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('workoutLogs')
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      return WorkoutLog.fromMap(doc.id, doc.data());
    }).toList();
  }

  Future<void> updateWorkoutLog(WorkoutLog log) async {
    final docRef = _firestore
        .collection('users')
        .doc(log.userId)
        .collection('workoutLogs')
        .doc(log.id);

    await docRef.update(log.toMap());
  }
}