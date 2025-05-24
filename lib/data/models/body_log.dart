class BodyLog {
  final DateTime date;
  final double weight;

  BodyLog({
    required this.date,
    required this.weight,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'weight': weight,
    };
  }

  factory BodyLog.fromJson(Map<String, dynamic> json) {
    return BodyLog(
      date: DateTime.parse(json['date']),
      weight: (json['weight'] as num).toDouble(),
    );
  }
}