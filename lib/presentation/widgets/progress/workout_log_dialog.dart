import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitness_app/data/models/workout_session_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils.dart';
import '../../../data/models/workout_log_model.dart';
import '../../../data/repositories/body_log_repository.dart';
import '../../../data/repositories/photo_progress_repository.dart';
import '../../../data/repositories/workout_log_repository.dart';
import '../../../logic/progress_bloc/progress_cubit.dart';
import '../../../services/achievement_service.dart';
import '../../../services/auth_service.dart';
import 'workout_log_edit_sheet.dart';

Future<void> showWorkoutLogDialog(BuildContext context, WorkoutLog log) async {
  final workoutLogCubit = context.read<WorkoutLogCubit>();

  await showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'WorkoutLogDialog',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(dialogContext).pop(),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
              child: Container(
                color: Colors.black.withValues(alpha: 0.3),
              ),
            ),
          ),
          Center(
            child: Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 100),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: BlocProvider.value(
                value: workoutLogCubit,
                child: WorkoutLogDialogContent(logId: log.id),
              ),
            ),
          ),
        ],
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: child,
        ),
      );
    },
  );
}


class WorkoutLogDialogContent extends StatelessWidget {
  final String logId;

  const WorkoutLogDialogContent({super.key, required this.logId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkoutLogCubit, WorkoutLogState>(
      builder: (context, state) {
        final log = state.logs.firstWhere(
          (l) => l.id == logId,
        );

        if (log.id.isEmpty) {
          return const Center(child: Text("Лог не найден"));
        }

        return _buildDialog(context, log);
      },
    );
  }

  Widget _buildDialog(BuildContext context, WorkoutLog log) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: const BoxConstraints(maxHeight: 600),
            decoration: BoxDecoration(
              color: theme.dialogTheme.backgroundColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Прокручиваемая часть
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Название и дата
                        Text(log.workoutName, style: textTheme.headlineSmall, textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        Text(
                          _formatDate(log.date),
                          style: textTheme.bodySmall?.copyWith(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),

                        // Основная информация
                        _infoRow("Цель", log.goal),
                        _infoRow("Вес", log.weight != null ? "${log.weight} кг" : null),
                        _infoRow("Настроение", log.mood),
                        _infoRow("Сложность", log.difficulty != null ? _buildStars(log.difficulty!) : null),
                        _infoRow("Длительность", "${log.durationMinutes} мин"),
                        const SizedBox(height: 12),

                        // Упражнения
                        ExpansionTile(
                          initiallyExpanded: false,
                          tilePadding: EdgeInsets.zero,
                          title: Text("Упражнения", style: textTheme.titleSmall),
                          childrenPadding: const EdgeInsets.only(top: 2),
                          children: log.exercises.map((e) => _exerciseTile(e, context)).toList(),
                        ),

                        const SizedBox(height: 12),

                        // Комментарий
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Комментарий", style: textTheme.titleMedium),
                              const SizedBox(height: 4),
                              Text(
                                (log.comment ?? "").isNotEmpty
                                    ? log.comment!
                                    : "Комментарий не был оставлен",
                                style: textTheme.bodyMedium?.copyWith(
                                  fontStyle: (log.comment ?? "").isNotEmpty ? null : FontStyle.italic,
                                  color: (log.comment ?? "").isNotEmpty ? null : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Фото (если есть)
                        if ((log.photoPath ?? "").isNotEmpty)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Фото", style: textTheme.titleMedium),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(log.photoPath!, height: 150, fit: BoxFit.cover),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Кнопки
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () async {
                          Navigator.of(context).pop();

                          final cubit = context.read<WorkoutLogCubit>();

                          final updatedLog = await showModalBottomSheet<WorkoutLog>(
                            context: context,
                            isScrollControlled: true,
                            builder: (context) => WorkoutLogEditSheet(initialLog: log),
                          );

                          if (updatedLog != null) {
                            final repository = WorkoutLogRepository();
                            await repository.updateWorkoutLog(updatedLog);
                            cubit.updateLog(updatedLog);

                            // ⬇️ Обновляем ачивки
                            final uid = AuthService().getCurrentUser()?.uid;
                            if (uid == null) return;

                            final workoutLogs = await WorkoutLogRepository().getWorkoutLogs(uid);
                            final photoLogs = await PhotoProgressRepository().loadEntries();
                            final bodyLogs = await BodyLogRepository(
                              firestore: FirebaseFirestore.instance,
                              userId: uid,
                            ).loadLogs();

                            await AchievementService().checkAndUpdateAchievements(
                              workoutLogs: workoutLogs,
                              photoEntries: photoLogs,
                              bodyLogs: bodyLogs,
                            );
                          }
                        },
                        child: Text(_isFullyFilled(log) ? "Редактировать" : "Дополнить"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("Закрыть"),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text("$label:")),
          const SizedBox(width: 8),
          Expanded(
            child: value == null
                ? Text("Не указано", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))
                : (value is Widget ? value : Text(value.toString())),
          ),
        ],
      ),
    );
  }

  Widget _buildStars(int value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < value ? Icons.star : Icons.star_border,
          size: 18,
          color: Colors.orange,
        );
      }),
    );
  }

  Widget _exerciseTile(ExerciseLog e, BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isSkipped = e.status == ExerciseStatus.skipped;

    return Padding(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(left: 8, right: 8),
        title: ExerciseNameText(
          e.id,
          style: textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: isSkipped ? Colors.grey : null,
          ),
        ),
        subtitle: isSkipped
            ? const Text("Пропущено", style: TextStyle(color: Colors.grey, fontSize: 12))
            : Text(
                _shortSetSummary(e),
                style: textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
        children: isSkipped
            ? []
            : e.sets.asMap().entries.map((entry) {
                final i = entry.key + 1;
                final s = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    "Подход $i: ${s.reps} повт. × ${s.weight ?? '-'} кг",
                    style: textTheme.bodySmall,
                  ),
                );
              }).toList(),
      ),
    );
  }

  String _shortSetSummary(ExerciseLog e) {
    return e.sets.map((s) {
      if (s.weight != null) {
        return "${s.reps}×${s.weight}";
      } else {
        return "–";
      }
    }).join(" / ");
  }

  String _formatDate(DateTime date) {
    final time = "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    return "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}, $time";
  }

  bool _isFullyFilled(WorkoutLog log) {
    return log.difficulty != null &&
        log.mood != null &&
        log.exercises.every((e) => e.sets.any((s) => s.weight != null));
  }
}