import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/locator.dart';
import '../../../core/utils.dart';
import '../../../data/models/workout_session_model.dart';
import '../../../data/repositories/workout_log_repository.dart';
import '../../../logic/progress_bloc/progress_cubit.dart';
import '../../../services/auth_service.dart';
import 'exercise_progress_detail_screen.dart';

class ExerciseProgressScreen extends StatelessWidget {
  const ExerciseProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Прогресс по упражнениям')),
      body: BlocBuilder<WorkoutLogCubit, WorkoutLogState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Собираем уникальные ID упражнений из всех логов
          final allExerciseLogs = state.logs.expand((log) => log.exercises);
          final uniqueExerciseIds = allExerciseLogs
              .where((e) => e.status == ExerciseStatus.done)
              .map((e) => e.id)
              .toSet()
              .toList();

          if (uniqueExerciseIds.isEmpty) {
            return const Center(child: Text('Нет данных для отображения.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: uniqueExerciseIds.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final id = uniqueExerciseIds[index];
              return ListTile(
                title: ExerciseNameText(id),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  final userId = locator<AuthService>().getCurrentUser()?.uid;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BlocProvider(
                        create: (_) => WorkoutLogCubit(
                          repository: locator<WorkoutLogRepository>(),
                          userId: userId!,
                        )..loadLogs(),
                        child: ExerciseProgressDetailScreen(exerciseId: id),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}