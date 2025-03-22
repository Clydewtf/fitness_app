class NutritionEntry {
  final String id;
  final String name;
  final int calories;
  final double protein;
  final double fats;
  final double carbs;
  final DateTime date;

  NutritionEntry({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.fats,
    required this.carbs,
    required this.date,
  });

  factory NutritionEntry.fromJson(Map<String, dynamic> json) {
    return NutritionEntry(
      id: json['id'],
      name: json['name'],
      calories: json['calories'],
      protein: json['protein'].toDouble(),
      fats: json['fats'].toDouble(),
      carbs: json['carbs'].toDouble(),
      date: DateTime.parse(json['date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
      'protein': protein,
      'fats': fats,
      'carbs': carbs,
      'date': date.toIso8601String(),
    };
  }
}