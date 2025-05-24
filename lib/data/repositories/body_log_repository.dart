import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/body_log.dart';

class BodyLogRepository {
  final FirebaseFirestore firestore;
  final String userId;

  BodyLogRepository({required this.firestore, required this.userId});

  CollectionReference get _collection =>
      firestore.collection('users').doc(userId).collection('bodyLogs');

  Future<void> addLog(BodyLog log) async {
    final id = log.date.toIso8601String();
    await _collection.doc(id).set(log.toJson());
  }

  Future<List<BodyLog>> loadLogs() async {
    final snapshot = await _collection.orderBy('date').get();
    return snapshot.docs
        .map((doc) => BodyLog.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<void> deleteLog(BodyLog log) async {
    final id = log.date.toIso8601String();
    await _collection.doc(id).delete();
  }

  Future<void> addOrUpdateWeightFromExternalSource(double weight, DateTime date, {required bool shouldUpdateProfile}) async {
    await addLog(BodyLog(date: date, weight: weight));
    if (shouldUpdateProfile) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({'weight': weight});
    }
  }
}