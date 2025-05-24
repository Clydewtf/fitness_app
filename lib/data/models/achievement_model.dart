enum AchievementStatus { locked, inProgress, unlocked }

class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int current;
  final int goal;
  final AchievementStatus status;
  final DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.current,
    required this.goal,
    required this.status,
    this.unlockedAt,
  });

  double get progress => goal == 0 ? 1.0 : current / goal;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'icon': icon,
        'current': current,
        'goal': goal,
        'status': status.name,
        'unlockedAt': unlockedAt?.toIso8601String(),
      };

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        icon: json['icon'],
        current: json['current'],
        goal: json['goal'],
        status: AchievementStatus.values.firstWhere((e) => e.name == json['status']),
        unlockedAt: json['unlockedAt'] != null ? DateTime.parse(json['unlockedAt']) : null,
      );
}