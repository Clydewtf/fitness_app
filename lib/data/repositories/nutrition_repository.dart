import 'package:shared_preferences/shared_preferences.dart';
import '../models/nutrition_model.dart';
import 'dart:convert';

class NutritionRepository {
  static const String _nutritionKey = "nutrition_data";

  Future<void> saveNutritionEntries(List<NutritionEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final entriesJson = jsonEncode(entries.map((e) => e.toJson()).toList());
    await prefs.setString(_nutritionKey, entriesJson);
  }

  Future<List<NutritionEntry>> loadNutritionEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final entriesJson = prefs.getString(_nutritionKey);
    
    if (entriesJson == null) return [];

    List<dynamic> decoded = jsonDecode(entriesJson);
    return decoded.map((e) => NutritionEntry.fromJson(e)).toList();
  }

  Future<void> clearNutritionEntries() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_nutritionKey);
  }
}