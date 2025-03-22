import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout_model.dart';
import 'dart:convert';

class WorkoutRepository {
  static const String _workoutsKey = "workouts_data";

  Future<void> saveWorkouts(List<WorkoutModel> workouts) async {
    final prefs = await SharedPreferences.getInstance();
    final workoutsJson = jsonEncode(workouts.map((w) => w.toJson()).toList());
    await prefs.setString(_workoutsKey, workoutsJson);
  }

  Future<List<WorkoutModel>> loadWorkouts() async {
    final prefs = await SharedPreferences.getInstance();
    final workoutsJson = prefs.getString(_workoutsKey);
    
    if (workoutsJson == null) return [];

    List<dynamic> decoded = jsonDecode(workoutsJson);
    return decoded.map((w) => WorkoutModel.fromJson(w)).toList();
  }

  Future<void> clearWorkouts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_workoutsKey);
  }
}