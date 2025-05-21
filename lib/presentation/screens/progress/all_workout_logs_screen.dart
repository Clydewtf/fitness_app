import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/locator.dart';
import '../../../core/utils.dart';
import '../../../data/repositories/workout_log_repository.dart';
import '../../../logic/progress_bloc/progress_cubit.dart';
import '../../../services/auth_service.dart';
import '../../../services/user_service.dart';
import '../../widgets/progress/recent_workout_card.dart';
import '../../widgets/progress/workout_log_dialog.dart';

class AllWorkoutLogsScreen extends StatelessWidget {
  const AllWorkoutLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = locator<AuthService>().getCurrentUser()?.uid;

    return BlocProvider(
      create: (_) => WorkoutLogCubit(
        repository: locator<WorkoutLogRepository>(),
        userId: userId!,
      )..loadLogs(),
      child: const _AllWorkoutLogsContent(),
    );
  }
}

class _AllWorkoutLogsContent extends StatefulWidget {
  const _AllWorkoutLogsContent();

  @override
  State<_AllWorkoutLogsContent> createState() => _AllWorkoutLogsContentState();
}

class _AllWorkoutLogsContentState extends State<_AllWorkoutLogsContent> {
  bool requireWeightsInSets = true;
  bool isLoadingSettings = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = UserSettingsStorage();
    final value = await settings.getRequireWeightsInSets();
    setState(() {
      requireWeightsInSets = value;
      isLoadingSettings = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<WorkoutLogCubit>().state;

    return Scaffold(
      appBar: AppBar(title: const Text('Все тренировки')),
      body: Builder(
        builder: (_) {
          if (state.isLoading || isLoadingSettings) {
            return const Center(child: CircularProgressIndicator());
          }

          final logs = state.logs;

          if (logs.isEmpty) {
            return const Center(child: Text("Нет завершённых тренировок"));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final log = logs[index];
              final isComplete = isLogComplete(log, requireWeightsInSets: requireWeightsInSets);
              final dateFormatted = DateFormat('d MMMM yyyy, HH:mm', 'ru').format(log.date);

              return RecentWorkoutCard(
                title: log.workoutName,
                date: dateFormatted,
                duration: '${log.durationMinutes} мин',
                isIncomplete: !isComplete,
                onTap: () => showWorkoutLogDialog(context, log),
              );
            },
          );
        },
      ),
    );
  }
}