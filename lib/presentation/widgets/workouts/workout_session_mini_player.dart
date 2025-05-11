import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/workout_session_model.dart';
import '../../../logic/workout_bloc/workout_session_bloc.dart';
import '../../screens/workouts/workout_in_progress_screen.dart';

enum PlayerAnchor { top, initial }

class WorkoutSessionMiniPlayer extends StatefulWidget {
  final WorkoutSession session;
  final int currentExercise;
  final bool isResting;
  final int restSecondsLeft;
  final double navBarHeight;

  const WorkoutSessionMiniPlayer({
    super.key,
    required this.session,
    required this.currentExercise,
    required this.isResting,
    required this.restSecondsLeft,
    required this.navBarHeight,
  });

  @override
  State<WorkoutSessionMiniPlayer> createState() => _WorkoutSessionMiniPlayerState();
}

class _WorkoutSessionMiniPlayerState extends State<WorkoutSessionMiniPlayer> with SingleTickerProviderStateMixin {
  double _dy = 0;
  late PlayerAnchor _currentAnchor;
  late double _screenHeight;
  final GlobalKey _playerKey = GlobalKey();
  double _playerHeight = 0;

  @override
  void initState() {
    super.initState();
    _currentAnchor = PlayerAnchor.initial;

    // Получаем высоту плеера после первой отрисовки
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _playerKey.currentContext;
      if (context != null) {
        final box = context.findRenderObject() as RenderBox;
        setState(() {
          _playerHeight = box.size.height;
        });
      }
    });
  }

  double _getAnchorOffset(PlayerAnchor anchor) {
    final viewPadding = MediaQuery.of(context).viewPadding;
    const extraPadding = 20;

    switch (anchor) {
      case PlayerAnchor.top:
        // Верхняя якорная точка — чуть ниже статус-бара
        return viewPadding.top + 50;
      case PlayerAnchor.initial:
        // Нижняя — прямо над нижним меню
        return _screenHeight - _playerHeight - widget.navBarHeight * 2 - extraPadding;
    }
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dy += details.delta.dy;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final top = _getAnchorOffset(PlayerAnchor.top);
    final initial = _getAnchorOffset(PlayerAnchor.initial);
    final currentPos = _getAnchorOffset(_currentAnchor) + _dy;

    final distances = {
      PlayerAnchor.top: (currentPos - top).abs(),
      PlayerAnchor.initial: (currentPos - initial).abs(),
    };

    final closestAnchor = distances.entries.reduce((a, b) => a.value < b.value ? a : b).key;

    setState(() {
      _currentAnchor = closestAnchor;
      _dy = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<WorkoutSessionBloc>().state;
    final exercises = widget.session.exercises;
    final total = exercises.length;
    final completed = exercises.where((e) =>
        e.status == ExerciseStatus.done || e.status == ExerciseStatus.skipped).length;
    final remaining = total - completed;

    final exerciseId = exercises[widget.currentExercise].exerciseId;
    final exercise = state.exercisesById[exerciseId];
    final exerciseName = exercise?.name ?? 'Упражнение';

    _screenHeight = MediaQuery.of(context).size.height;
    final topOffset = _getAnchorOffset(_currentAnchor) + _dy;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      left: 0,
      right: 0,
      top: topOffset,
      child: GestureDetector(
        onPanUpdate: _onDragUpdate,
        onPanEnd: _onDragEnd,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<WorkoutSessionBloc>(),
                child: const WorkoutInProgressScreen(),
              ),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2D2F),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(70),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.fitness_center, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exerciseName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        ...List.generate(total, (index) {
                          final isCurrent = index == widget.currentExercise;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCurrent ? Colors.white : Colors.white38,
                            ),
                          );
                        }),
                        const SizedBox(width: 8),
                        Text(
                          '$remaining осталось',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    WorkoutTimer(
                      startTime: widget.session.startTime,
                      endTime: widget.session.endTime,
                      textStyle: const TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                  ],
                ),
              ),
              if (widget.isResting)
                Row(
                  children: [
                    const RestIndicator(),
                    const SizedBox(width: 3),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Отдых',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Text(
                          _formatSeconds(widget.restSecondsLeft),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white, size: 28),
            ],
          ),
        ),
      ),
    );
  }

  String _formatSeconds(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

class RestIndicator extends StatefulWidget {
  const RestIndicator({super.key});

  @override
  State<RestIndicator> createState() => _RestIndicatorState();
}

class _RestIndicatorState extends State<RestIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller.drive(CurveTween(curve: Curves.easeInOut)),
      child: const Icon(Icons.hourglass_empty, color: Colors.white70, size: 24),
    );
  }
}