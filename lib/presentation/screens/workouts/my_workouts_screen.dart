import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/workout_bloc/my_workout_bloc.dart';
import '../../../logic/workout_bloc/my_workout_event.dart';
import '../../../logic/workout_bloc/my_workout_state.dart';
import '../../../services/auth_service.dart';
import '../../widgets/workouts/workout_card.dart';
import '../workouts/workout_create_screen.dart';

class MyWorkoutsScreen extends StatelessWidget {
  const MyWorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои тренировки'),
      ),
      body: BlocBuilder<MyWorkoutBloc, MyWorkoutState>(
        builder: (context, state) {
          if (state is MyWorkoutLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is MyWorkoutLoaded) {
            final workouts = state.workouts;

            if (workouts.isEmpty) {
              return const Center(child: Text('У вас пока нет созданных тренировок.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: workouts.length,
              itemBuilder: (context, index) {
                final workout = workouts[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: WorkoutCard(
                    workout: workout,
                    isMyWorkout: true,
                  ),
                );
              },
            );
          } else if (state is MyWorkoutError) {
            return Center(child: Text('Ошибка: ${state.message}'));
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final uid = AuthService().getCurrentUser()?.uid;
          if (uid == null) return;

          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const CreateWorkoutScreen(),
            ),
          );
          
          if (result != null && context.mounted) {
            context.read<MyWorkoutBloc>().add(LoadMyWorkouts(uid));
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Создать'),
      ),
    );
  }
}