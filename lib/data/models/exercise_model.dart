class Exercise {
  final String id;
  final String name;
  final String muscleGroup; // грудь, спина, ноги и т.д.
  final String type; // силовая, кардио и т.п.
  final String equipment; // гантели, турник, вес тела и т.п.
  final String? description;
  final String? imageUrl;

  Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    required this.type,
    required this.equipment,
    this.description,
    this.imageUrl,
  });

  factory Exercise.fromMap(Map<String, dynamic> map, String id) {
    return Exercise(
      id: id,
      name: map['name'] ?? '',
      muscleGroup: map['muscleGroup'] ?? '',
      type: map['type'] ?? '',
      equipment: map['equipment'] ?? '',
      description: map['description'],
      imageUrl: map['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'muscleGroup': muscleGroup,
      'type': type,
      'equipment': equipment,
      'description': description,
      'imageUrl': imageUrl,
    };
  }
}