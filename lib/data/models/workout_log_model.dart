import 'workout_session_model.dart';

class WorkoutLog {
  final String id;
  final String userId;
  final String workoutId;
  final String workoutName;
  final String goal;
  final DateTime date;
  final int durationMinutes;
  final int difficulty;
  final String mood;
  final String? comment;
  final String? photoPath;

  final List<ExerciseLog> exercises;

  WorkoutLog({
    required this.id,
    required this.userId,
    required this.workoutId,
    required this.workoutName,
    required this.goal,
    required this.date,
    required this.durationMinutes,
    required this.difficulty,
    required this.mood,
    this.comment,
    this.photoPath,
    required this.exercises,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'workoutId': workoutId,
      'workoutName': workoutName,
      'goal': goal,
      'date': date.toIso8601String(),
      'durationMinutes': durationMinutes,
      'difficulty': difficulty,
      'mood': mood,
      'comment': comment,
      'photoPath': photoPath,
      'exercises': exercises.map((e) => e.toMap()).toList(),
    };
  }

  factory WorkoutLog.fromMap(String id, Map<String, dynamic> map) {
    return WorkoutLog(
      id: id,
      userId: map['userId'],
      workoutId: map['workoutId'],
      workoutName: map['workoutName'],
      goal: map['goal'],
      date: DateTime.parse(map['date']),
      durationMinutes: map['durationMinutes'],
      difficulty: map['difficulty'],
      mood: map['mood'],
      comment: map['comment'],
      photoPath: map['photoPath'],
      exercises: (map['exercises'] as List)
          .map((e) => ExerciseLog.fromMap(e))
          .toList(),
    );
  }
}

class ExerciseLog {
  final String id;
  final int sets;
  final int reps;
  final int restSeconds;
  final ExerciseStatus status;

  ExerciseLog({
    required this.id,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sets': sets,
      'reps': reps,
      'restSeconds': restSeconds,
      'status': status.name,
    };
  }

  factory ExerciseLog.fromMap(Map<String, dynamic> map) {
    return ExerciseLog(
      id: map['id'],
      sets: map['sets'],
      reps: map['reps'],
      restSeconds: map['restSeconds'],
      status: ExerciseStatus.values.byName(map['status']),
    );
  }
}