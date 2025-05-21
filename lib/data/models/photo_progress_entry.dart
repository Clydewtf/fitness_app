class PhotoProgressEntry {
  final String path;
  final DateTime date;
  final String pose;

  PhotoProgressEntry({
    required this.path,
    required this.date,
    required this.pose,
  });

  Map<String, dynamic> toJson() => {
    'path': path,
    'date': date.toIso8601String(),
    'pose': pose,
  };

  factory PhotoProgressEntry.fromJson(Map<String, dynamic> json) {
    return PhotoProgressEntry(
      path: json['path'],
      date: DateTime.parse(json['date']),
      pose: json['pose'] as String? ?? 'неизвестно',
    );
  }
}