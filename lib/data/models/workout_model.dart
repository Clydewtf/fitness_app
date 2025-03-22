class Exercise {
  final String name;
  final int sets;
  final int reps;
  final double weight;

  Exercise({
    required this.name,
    required this.sets,
    required this.reps,
    required this.weight,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      name: json['name'],
      sets: json['sets'],
      reps: json['reps'],
      weight: json['weight'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'sets': sets,
      'reps': reps,
      'weight': weight,
    };
  }
}

class WorkoutModel {
  final String id;
  final String name;
  final List<Exercise> exercises;
  final DateTime date;

  WorkoutModel({
    required this.id,
    required this.name,
    required this.exercises,
    required this.date,
  });

  factory WorkoutModel.fromJson(Map<String, dynamic> json) {
    return WorkoutModel(
      id: json['id'],
      name: json['name'],
      exercises: (json['exercises'] as List)
          .map((e) => Exercise.fromJson(e))
          .toList(),
      date: DateTime.parse(json['date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'date': date.toIso8601String(),
    };
  }
}