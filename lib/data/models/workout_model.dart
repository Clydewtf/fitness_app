class Workout {
  final String id;
  final String name;
  final String? tagline;
  final String? description;
  final String level; // например: новичок, средний, продвинутый
  final String type; // например: силовая, кардио
  final List<String> targetGoals; // список целей: сушка, масса и т.п.
  final List<String> muscleGroups; // задействованные основные мышцы
  final List<WorkoutExercise> exercises; // список упражнений с подходами/повторами
  final int duration; // продолжительность в минутах (можно примерно)
  final bool isFavorite;
  
  Workout({
    required this.id,
    required this.name,
    this.tagline,
    this.description,
    required this.level,
    required this.type,
    required this.targetGoals,
    required this.muscleGroups,
    required this.exercises,
    required this.duration,
    this.isFavorite = false,
  });

  Workout copyWith({
    String? id,
    String? name,
    String? tagline,
    String? description,
    String? level,
    String? type,
    List<String>? targetGoals,
    List<String>? muscleGroups,
    List<WorkoutExercise>? exercises,
    int? duration,
    bool? isFavorite,
  }) {
    return Workout(
      id: id ?? this.id,
      name: name ?? this.name,
      tagline: tagline ?? this.tagline,
      description: description ?? this.description,
      level: level ?? this.level,
      type: type ?? this.type,
      targetGoals: targetGoals ?? this.targetGoals,
      muscleGroups: muscleGroups ?? this.muscleGroups,
      exercises: exercises ?? this.exercises,
      duration: duration ?? this.duration,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  factory Workout.fromMap(Map<String, dynamic> map, String id) {
    return Workout(
      id: id,
      name: map['name'],
      tagline: map['tagline'],
      description: map['description'],
      level: map['level'],
      type: map['type'],
      targetGoals: List<String>.from(map['targetGoals'] ?? []),
      muscleGroups: List<String>.from(map['muscleGroups'] ?? []),
      exercises: (map['exercises'] as List)
          .map((e) => WorkoutExercise.fromMap(e))
          .toList(),
      duration: map['duration'] ?? 0,
      isFavorite: map['isFavorite'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'tagline': tagline,
      'description': description,
      'level': level,
      'type': type,
      'targetGoals': targetGoals,
      'muscleGroups': muscleGroups,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'duration': duration,
      'isFavorite': isFavorite,
    };
  }
}

class WorkoutExercise {
  final String exerciseId;
  final Map<String, WorkoutMode> modes; // цель → параметры

  WorkoutExercise({
    required this.exerciseId,
    required this.modes,
  });

  factory WorkoutExercise.fromMap(Map<String, dynamic> map) {
    return WorkoutExercise(
      exerciseId: map['exerciseId'],
      modes: (map['modes'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, WorkoutMode.fromMap(value)),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'exerciseId': exerciseId,
      'modes': modes.map((key, value) => MapEntry(key, value.toMap())),
    };
  }
}

class WorkoutMode {
  final int sets;
  final int reps;
  final int restSeconds;

  WorkoutMode({
    required this.sets,
    required this.reps,
    required this.restSeconds,
  });

  factory WorkoutMode.fromMap(Map<String, dynamic> map) {
    return WorkoutMode(
      sets: map['sets'],
      reps: map['reps'],
      restSeconds: map['restSeconds'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sets': sets,
      'reps': reps,
      'restSeconds': restSeconds,
    };
  }
}