class Exercise {
  final String id;
  final String name;
  final String level; // новичок, средний, продвинутый
  final String type; // силовая, кардио, статическая и т.д.
  final String equipment; // гантели, вес тела и т.п.
  final String? description; // краткое описание (для карточки)
  final List<String> instructions; // подробные инструкции (экран описания)
  final List<String>? imageUrls;
  final List<String> primaryMuscles;
  final List<String>? secondaryMuscles;

  Exercise({
    required this.id,
    required this.name,
    required this.level,
    required this.type,
    required this.equipment,
    this.description,
    required this.instructions,
    this.imageUrls,
    required this.primaryMuscles,
    this.secondaryMuscles,
  });

  factory Exercise.fromMap(Map<String, dynamic> map, String id) {
    return Exercise(
      id: id,
      name: map['name'],
      level: map['level'],
      type: map['type'],
      equipment: map['equipment'],
      description: map['description'],
      instructions: List<String>.from(map['instructions'] ?? []),
      imageUrls: map['imageUrls'] != null ? List<String>.from(map['imageUrls']) : null,
      primaryMuscles: List<String>.from(map['primaryMuscles'] ?? []),
      secondaryMuscles: map['secondaryMuscles'] != null ? List<String>.from(map['secondaryMuscles']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'level': level,
      'type': type,
      'equipment': equipment,
      'description': description,
      'instructions': instructions,
      'imageUrls': imageUrls,
      'primaryMuscles': primaryMuscles,
      'secondaryMuscles': secondaryMuscles,
    };
  }
}