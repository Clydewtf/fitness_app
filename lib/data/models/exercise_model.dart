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

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'],
      name: json['name'],
      muscleGroup: json['muscleGroup'],
      type: json['type'],
      equipment: json['equipment'],
      description: json['description'],
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'muscleGroup': muscleGroup,
      'type': type,
      'equipment': equipment,
      'description': description,
      'imageUrl': imageUrl,
    };
  }
}