import 'dart:io';
import 'package:fitness_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/locator.dart';
import '../../../core/utils.dart';
import '../../../data/models/exercise_model.dart';
import '../../../data/models/workout_log_model.dart';
import '../../../data/models/workout_session_model.dart';
import '../../../services/user_service.dart';
import '../../../data/repositories/workout_log_repository.dart';

class WorkoutSummaryBottomSheet extends StatefulWidget {
  final WorkoutSession session;
  final int completed;
  final int total;
  final Duration duration;
  final void Function({
    required int difficulty,
    required String mood,
    String? comment,
    File? photo,
    double? weight,
  })? onFinished;

  final Map<String, Exercise> exercisesById;

  const WorkoutSummaryBottomSheet({
    super.key,
    required this.session,
    required this.completed,
    required this.total,
    required this.duration,
    this.onFinished,
    required this.exercisesById,
  });

  @override
  State<WorkoutSummaryBottomSheet> createState() => _WorkoutSummaryBottomSheetState();
}

class _WorkoutSummaryBottomSheetState extends State<WorkoutSummaryBottomSheet> {
  int step = 1;
  int? selectedDifficulty;
  String? selectedMood;
  String? comment;
  File? selectedImage;
  double? weight;

  final moodOptions = ['😍', '🙂', '😐', '😩', '🤒'];

  final ImagePicker _picker = ImagePicker();
  final UserService _userService = UserService();
  final authService = locator<AuthService>();
  final WorkoutLogRepository _logRepository = WorkoutLogRepository();

  WorkoutLog? _previousLog;
  Duration? _daysAgo;
  bool get hasPreviousLog => _previousLog != null;
  

  String get timeText =>
      "${widget.duration.inMinutes} мин ${widget.duration.inSeconds % 60} сек";

  @override
  void initState() {
    super.initState();
    _loadUserWeight();
    _loadPreviousLog();

    for (var e in widget.session.exercises) {
      // Только для выполненных упражнений и если sets ещё не заданы
      if (e.status == ExerciseStatus.done && e.sets == null) {
        e.sets = List.generate(
          e.workoutMode.sets,
          (_) => ExerciseSetLog(weight: 0, reps: e.workoutMode.reps),
        );
      }
    }
  }

  Future<void> _loadUserWeight() async {
    final uid = authService.getCurrentUser()?.uid;
    if (uid != null) {
      final fetchedWeight = await _userService.getUserWeight(uid);
      if (fetchedWeight != null) {
        setState(() {
          weight = fetchedWeight;
        });
      }
    }
  }

  Future<void> _loadPreviousLog() async {
    final uid = authService.getCurrentUser()?.uid;
    if (uid == null) return;

    final logs = await _logRepository.getWorkoutLogs(uid);
    if (logs.isEmpty) return;

    final matchingLogs = logs.where((log) => log.workoutId == widget.session.workoutId).toList();
    if (matchingLogs.isNotEmpty) {
      setState(() {
        _previousLog = matchingLogs.first;
        _daysAgo = DateTime.now().difference(_previousLog!.date);
      });
    }
  }

  Future<void> applyPreviousSets() async {
    if (_previousLog == null) return;

    final latestLogsByExercise = {
      for (var log in _previousLog!.exercises) log.id: log
    };

    int filledCount = 0;

    setState(() {
      for (var current in widget.session.exercises.where((e) => e.status == ExerciseStatus.done)) {
        final prevLog = latestLogsByExercise[current.exerciseId];
        if (prevLog != null) {
          current.sets = prevLog.sets
              .map((s) => ExerciseSetLog(weight: s.weight, reps: s.reps))
              .toList();
          filledCount++;
        }
      }
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          filledCount > 0
              ? 'Заполнено из прошлой тренировки: $filledCount упражнений'
              : 'Совпадающие упражнения не найдены',
        ),
      ),
    );
  }

  void nextStep() {
    if (step < 3) {
      setState(() => step += 1);
    } else {
      widget.onFinished?.call(
        difficulty: selectedDifficulty ?? 3,
        mood: selectedMood ?? '😐',
        comment: comment,
        photo: selectedImage,
        weight: weight,
      );
      Navigator.of(context).pop(true);
    }
  }

  void skip() {
    widget.onFinished?.call(
      difficulty: selectedDifficulty ?? 3,
      mood: selectedMood ?? '😐',
      comment: null,
      photo: null,
      weight: null,
    );
    Navigator.of(context).pop();
  }

  Future<void> pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => selectedImage = File(picked.path));
    }
  }

  double _getSheetHeightForStep(int step) {
    switch (step) {
      case 1:
        return 300;
      case 2:
        return 410;
      case 3:
        return 660;
      default:
        return 300;
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = _getSheetHeightForStep(step);
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        child: Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: SizedBox(
            height: height,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDragHandle(),
                const SizedBox(height: 12),
                Text('Тренировка завершена', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text('Выполнено: ${widget.completed} из ${widget.total}',
                    style: Theme.of(context).textTheme.bodyMedium),
                Text('⏱ $timeText', style: Theme.of(context).textTheme.bodySmall),
                const Divider(height: 32),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildStepContent(),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: skip,
                                child: const Text('Пропустить')
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: nextStep,
                                child: Text(step < 3 ? 'Далее' : 'Готово'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey[400],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    List<Widget> steps = [];
    final doneExercises = widget.session.exercises.where((e) => e.status == ExerciseStatus.done).toList();

    if (step >= 1) {
      steps.add(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Как оценишь сложность?', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              final isSelected = (selectedDifficulty ?? 0) > index;

              return IconButton(
                onPressed: () => setState(() => selectedDifficulty = index + 1),
                icon: Icon(
                  isSelected ? Icons.star : Icons.star_border,
                  size: 36,
                  color: isSelected ? Colors.amber : Colors.grey[400],
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
        ],
      ));
    }

    if (step >= 2) {
      steps.add(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Как самочувствие?', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: moodOptions.map((mood) {
              final isSelected = selectedMood == mood;
              return GestureDetector(
                onTap: () => setState(() => selectedMood = mood),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? const Color.fromARGB(255, 250, 219, 125).withValues(alpha: 0.2) : null,
                    border: isSelected
                        ? Border.all(color: Colors.amber, width: 2)
                        : null,
                  ),
                  child: Text(
                    mood,
                    style: const TextStyle(fontSize: 30),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],
      ));
    }

    if (step >= 3) {
      steps.add(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 💪 ВЕС ПОЛЬЗОВАТЕЛЯ
          Center(
            child: SizedBox(
              width: 240,
              child: IncrementableField(
                label: 'Вес (кг, опционально)',
                value: weight ?? 70.0,
                step: 0.5,
                onChanged: (val) => weight = val,
                hintText: 'Например: 70.5',
                min: 0,
                max: 300,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 💬 КОММЕНТАРИЙ
          TextField(
            onChanged: (val) => comment = val,
            decoration: const InputDecoration(
              labelText: 'Комментарий (опционально)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),

          // 📸 ИЗОБРАЖЕНИЕ
          Text('Добавить фото прогресса (опционально)',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: pickImage,
            child: Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: selectedImage != null
                  ? Image.file(selectedImage!, fit: BoxFit.cover)
                  : const Icon(Icons.camera_alt, size: 32, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 24),

          if (hasPreviousLog && _daysAgo != null) ...[
            Text(
              'Вы выполняли эту тренировку ${_formatDaysAgo(_daysAgo!)}. '
              'Заполнить прошлые значения?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Center(
              child: TextButton.icon(
                onPressed: applyPreviousSets,
                icon: const Icon(Icons.history),
                label: const Text('Повторить прошлые'),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // 🏋️‍♂️ УПРАЖНЕНИЯ
          Text('Упражнения (необязательно)', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...doneExercises.map((log) {
            final sets = log.sets ?? [];
            final name = widget.exercisesById[log.exerciseId]?.name ?? 'Упражнение';

            return ExpansionTile(
              title: Text('Упражнение: $name'),
              subtitle: const Text('Нажмите, чтобы ввести подходы'),
              children: List.generate(sets.length, (i) {
                final set = sets[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: IncrementableField(
                          label: 'Повторы',
                          value: set.reps.toDouble(),
                          step: 1,
                          min: 0,
                          max: 100,
                          isInteger: true,
                          onChanged: (val) => set.reps = val.round(),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: IncrementableField(
                          label: 'Вес (кг)',
                          value: set.weight?.toDouble() ?? 0.0,
                          step: 2.5,
                          min: 0,
                          max: 500,
                          onChanged: (val) => set.weight = val,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            );
          }),
        ],
      ));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: steps,
      ),
    );
  }

  String _formatDaysAgo(Duration duration) {
    final days = duration.inDays;
    if (days == 0) return 'сегодня';
    if (days == 1) return 'вчера';
    return '$days дней назад';
  }
}