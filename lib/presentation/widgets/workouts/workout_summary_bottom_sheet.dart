import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/models/workout_session_model.dart';

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
  })? onFinished;

  const WorkoutSummaryBottomSheet({
    super.key,
    required this.session,
    required this.completed,
    required this.total,
    required this.duration,
    this.onFinished,
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

  final moodOptions = ['😍', '🙂', '😐', '😩', '🤒'];

  final ImagePicker _picker = ImagePicker();

  String get timeText =>
      "${widget.duration.inMinutes} мин ${widget.duration.inSeconds % 60} сек";

  void nextStep() {
    if (step < 3) {
      setState(() => step += 1);
    } else {
      widget.onFinished?.call(
        difficulty: selectedDifficulty ?? 3,
        mood: selectedMood ?? '😐',
        comment: comment,
        photo: selectedImage,
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
    return AnimatedSize(
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
          TextField(
            onChanged: (val) => comment = val,
            decoration: const InputDecoration(
              labelText: 'Комментарий (необязательно)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
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
        ],
      ));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: steps,
      ),
    );
  }
}