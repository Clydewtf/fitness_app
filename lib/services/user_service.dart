import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
    if (userDoc.exists) {
      return userDoc.data() as Map<String, dynamic>;
    }
    return null;
  }

  Future<void> updateUserData(String uid, Map<String, dynamic> updatedData) async {
    await _firestore.collection('users').doc(uid).update(updatedData);
  }

  Future<double?> getUserWeight(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final weight = data['weight'];
      if (weight != null) {
        return (weight as num).toDouble();
      }
    }
    return null;
  }

  Future<String?> getUserGoal(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final goal = data['goal'];
      if (goal != null && goal is String && goal.isNotEmpty) {
        return goal;
      }
    }
    return null;
  }

  // Сохраняем фото локально
  Future<String?> saveProfileImage(File imageFile) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final String path = '${directory.path}/profile.jpg';
      await imageFile.copy(path);

      // Сохраняем путь к файлу в SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image', path);

      return path;
    } catch (e) {
      if (kDebugMode) {
        print("Ошибка сохранения фото: $e");
      }
      return null;
    }
  }

  // Загружаем сохранённое фото
  Future<String?> getProfileImage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('profile_image');
  }

  // Получить список избранных тренировок
  Future<List<String>> getFavoriteWorkouts(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data();
    if (data != null && data['favoriteWorkouts'] != null) {
      return List<String>.from(data['favoriteWorkouts']);
    }
    return [];
  }

  // Добавить тренировку в избранное
  Future<void> addFavoriteWorkout(String uid, String workoutId) async {
    await _firestore.collection('users').doc(uid).update({
      'favoriteWorkouts': FieldValue.arrayUnion([workoutId])
    });
  }

  // Удалить тренировку из избранного
  Future<void> removeFavoriteWorkout(String uid, String workoutId) async {
    await _firestore.collection('users').doc(uid).update({
      'favoriteWorkouts': FieldValue.arrayRemove([workoutId])
    });
  }
}

class UserSettingsStorage {
  static const _keyRequireWeights = 'require_weights_in_sets';
  static const _autoUpdateWeightKey = 'auto_update_weight';

  Future<bool> getRequireWeightsInSets() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyRequireWeights) ?? true;
  }

  Future<void> setRequireWeightsInSets(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRequireWeights, value);
  }

  Future<bool> getAutoUpdateWeight() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoUpdateWeightKey) ?? true; // по умолчанию ВКЛ
  }

  Future<void> setAutoUpdateWeight(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoUpdateWeightKey, value);
  }
}