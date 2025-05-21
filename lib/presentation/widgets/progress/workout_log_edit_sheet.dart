import 'package:fitness_app/data/models/workout_session_model.dart';
import 'package:flutter/material.dart';
import '../../../core/utils.dart';
import '../../../data/models/workout_log_model.dart';

class WorkoutLogEditSheet extends StatefulWidget {
  final WorkoutLog initialLog;

  const WorkoutLogEditSheet({super.key, required this.initialLog});

  @override
  State<WorkoutLogEditSheet> createState() => _WorkoutLogEditSheetState();
}

class _WorkoutLogEditSheetState extends State<WorkoutLogEditSheet> {
  late WorkoutLog log;

  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    log = widget.initialLog.copyWith();
    _commentController.text = log.comment ?? '';
    _weightController.text = log.weight?.toString() ?? '';
  }

  void _updateSet(int exIndex, int setIndex, {int? reps, double? weight}) {
    final newSets = List.of(log.exercises[exIndex].sets);
    final updatedSet = newSets[setIndex].copyWith(
      reps: reps ?? newSets[setIndex].reps,
      weight: weight ?? newSets[setIndex].weight,
    );
    newSets[setIndex] = updatedSet;

    final updatedExercise = log.exercises[exIndex].copyWith(sets: newSets);
    final newExercises = List.of(log.exercises);
    newExercises[exIndex] = updatedExercise;

    setState(() {
      log = log.copyWith(exercises: newExercises);
    });
  }

  void _save() {
    final updatedLog = log.copyWith(
      comment: _commentController.text.trim().isEmpty
          ? null
          : _commentController.text.trim(),
      weight: double.tryParse(_weightController.text),
    );
    Navigator.of(context).pop(updatedLog);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  log.workoutName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                _buildMoodSelector(),
                const SizedBox(height: 12),
                _buildDifficultySelector(),
                const SizedBox(height: 12),
                _buildWeightField(),
                const SizedBox(height: 12),
                _buildCommentField(),
                const SizedBox(height: 20),
                const Text("Упражнения", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...log.exercises.asMap().entries.map((entry) {
                  final i = entry.key;
                  final exercise = entry.value;
                  final isEditable = exercise.status == ExerciseStatus.done;

                  if (!isEditable) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ExerciseNameText(exercise.id, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text(
                          "Упражнение было пропущено",
                          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ExerciseNameText(exercise.id, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...exercise.sets.asMap().entries.map((setEntry) {
                        final j = setEntry.key;
                        final set = setEntry.value;
                        final repsController = TextEditingController(text: set.reps.toString());
                        final weightController = TextEditingController(text: set.weight?.toString() ?? '');

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Text("Сет ${j + 1}: "),
                              Expanded(
                                child: TextField(
                                  controller: repsController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Повторы',
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                  onChanged: (val) => _updateSet(i, j, reps: int.tryParse(val)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: weightController,
                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: 'Вес (кг)',
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                  onChanged: (val) => _updateSet(i, j, weight: double.tryParse(val)),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                    ],
                  );
                }),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("Отмена"),
                    ),
                    ElevatedButton(
                      onPressed: _save,
                      child: const Text("Сохранить"),
                    ),
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMoodSelector() {
    final moods = ['😍', '🙂', '😐', '😩', '🤒'];
    return Column(
      children: [
        const Text("Настроение:", style: TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var mood in moods)
              GestureDetector(
                onTap: () => setState(() => log = log.copyWith(mood: mood)),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: log.mood == mood ? Colors.blue.shade100 : null,
                    shape: BoxShape.circle,
                  ),
                  child: Text(mood, style: const TextStyle(fontSize: 28)),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDifficultySelector() {
    return Column(
      children: [
        const Text("Сложность:", style: TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 1; i <= 5; i++)
              IconButton(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                constraints: const BoxConstraints(),
                icon: Icon(
                  Icons.star,
                  size: 32,
                  color: log.difficulty != null && log.difficulty! >= i
                      ? Colors.orange
                      : Colors.grey,
                ),
                onPressed: () => setState(() => log = log.copyWith(difficulty: i)),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeightField() {
    return Center(
      child: SizedBox(
        width: 180,
        child: TextField(
          controller: _weightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Ваш вес (кг)',
            prefixIcon: Icon(Icons.monitor_weight),
          ),
        ),
      ),
    );
  }

  Widget _buildCommentField() {
    return TextField(
      controller: _commentController,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'Комментарий',
        prefixIcon: Icon(Icons.comment),
      ),
    );
  }
}