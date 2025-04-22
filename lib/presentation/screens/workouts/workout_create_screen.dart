import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_app/presentation/screens/workouts/workout_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/exercise_model.dart';
import '../../../data/models/workout_model.dart';
import '../../../data/repositories/exercise_repository.dart';
import '../../../data/repositories/my_workout_repository.dart';
import '../../../logic/workout_bloc/my_workout_bloc.dart';
import '../../../logic/workout_bloc/my_workout_event.dart';
import '../../widgets/workouts/exercise_card.dart';

class CreateWorkoutScreen extends StatefulWidget {
  final Workout? existingWorkout;
  const CreateWorkoutScreen({super.key, this.existingWorkout});

  @override
  State<CreateWorkoutScreen> createState() => _CreateWorkoutScreenState();
}

class _CreateWorkoutScreenState extends State<CreateWorkoutScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _taglineController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();

  // Выбор из списка или "свой вариант"
  String? selectedLevel;
  String? selectedType;
  List<String> selectedGoals = [];
  List<Exercise> selectedExercises = [];
  Map<String, Map<String, WorkoutMode>> exerciseModesByGoal = {};

  bool customLevel = false;
  bool customType = false;
  bool customGoal = false;

  final _customLevelController = TextEditingController();
  final _customTypeController = TextEditingController();
  final _customGoalController = TextEditingController();

  // Примерные варианты
  final levels = ['Новичок', 'Средний', 'Продвинутый'];
  final types = ['Силовая', 'Кардио', 'Растяжка', 'Плиометрика', 'Стронгмен',
      'Пауэрлифтинг', 'Тяжёлая атлетика', 'Кроссфит', 'Функциональная'];
  final goals = ['Поддержание формы', 'Набор массы', 'Сушка', 'Сила', 'Выносливость'];

  @override
  void initState() {
    super.initState();

    final workout = widget.existingWorkout;
    if (workout != null) {
      _nameController.text = workout.name;
      _taglineController.text = workout.tagline ?? '';
      _descriptionController.text = workout.description ?? '';
      _durationController.text = workout.duration.toString();
      selectedLevel = workout.level;
      selectedType = workout.type;
      selectedGoals = List.from(workout.targetGoals);
      selectedExercises = []; // Заполним ниже из workout.exercises

      // Здесь можно будет загрузить полные объекты Exercise по id
      Future.microtask(() async {
        final repo = ExerciseRepository();
        final exercises = await Future.wait(
          workout.exercises.map((e) => repo.getExerciseById(e.exerciseId)),
        );

        setState(() {
          selectedExercises = exercises.whereType<Exercise>().toList();

          for (final workoutExercise in workout.exercises) {
            for (final entry in workoutExercise.modes.entries) {
              exerciseModesByGoal.putIfAbsent(entry.key, () => {});
              exerciseModesByGoal[entry.key]![workoutExercise.exerciseId] = entry.value;
            }
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _taglineController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _customLevelController.dispose();
    _customTypeController.dispose();
    _customGoalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Создание тренировки')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text('Название *'),
              TextFormField(
                controller: _nameController,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Введите название' : null,
              ),
              const SizedBox(height: 16),

              const Text('Краткое описание'),
              TextFormField(
                controller: _taglineController,
              ),
              const SizedBox(height: 16),

              // Уровень
              _buildDropdownOrCustom(
                label: 'Уровень *',
                items: levels,
                selectedItem: selectedLevel,
                customEnabled: customLevel,
                onChanged: (val) => setState(() => selectedLevel = val),
                onToggleCustom: () =>
                    setState(() => customLevel = !customLevel),
                customController: _customLevelController,
              ),
              const SizedBox(height: 16),

              // Тип
              _buildDropdownOrCustom(
                label: 'Тип *',
                items: types,
                selectedItem: selectedType,
                customEnabled: customType,
                onChanged: (val) => setState(() => selectedType = val),
                onToggleCustom: () =>
                    setState(() => customType = !customType),
                customController: _customTypeController,
              ),
              const SizedBox(height: 16),

              // Цели
              _buildMultiSelectOrCustom(),
              const SizedBox(height: 16),

              const Text('Продолжительность (мин) *'),
              TextFormField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Укажите время' : null,
              ),
              const SizedBox(height: 16),

              const Text('Подробное описание'),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              const Text('Упражнения *'),
              ElevatedButton.icon(
                onPressed: () async {
                  final selected = await Navigator.push<List<Exercise>>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ExercisesTab(
                        isSelectionMode: true,
                        initiallySelected: selectedExercises, // если нужно
                        selectedMuscleGroup: null,
                        selectedType: null,
                        selectedEquipment: null,
                        selectedLevels: const [],
                        onFilterChanged: ({muscleGroup, type, equipment, levels}) {},
                        onOpenFilter: (ctx, groups, types, eq) {},
                        onSelectionDone: (selectedExercises) {
                          Navigator.pop(context, selectedExercises);
                        },
                      ),
                    ),
                  );

                  if (selected != null && selected.isNotEmpty) {
                    setState(() {
                      selectedExercises = selected;
                    });
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Добавить упражнения'),
              ),

              if (selectedExercises.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Выбранные упражнения:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: selectedExercises.length,
                  itemBuilder: (context, index) {
                    final exercise = selectedExercises[index];
                    return Dismissible(
                      key: ValueKey(exercise.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) {
                        setState(() {
                          selectedExercises.removeAt(index);
                        });
                      },
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: ExerciseCard(exercise: exercise),
                    );
                  },
                ),
              ],

              if (selectedExercises.isNotEmpty && selectedGoals.isNotEmpty)
                _buildExerciseModesSection(),

              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    if (selectedExercises.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Добавьте хотя бы одно упражнение')),
                      );
                      return;
                    }

                    if (selectedGoals.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Выберите хотя бы одну цель')),
                      );
                      return;
                    }

                    try {
                      // 1. Собираем данные из формы
                      final name = _nameController.text.trim();
                      final tagline = _taglineController.text.trim();
                      final description = _descriptionController.text.trim();
                      final level = customLevel
                          ? _customLevelController.text.trim()
                          : selectedLevel ?? '';
                      final type = customType
                          ? _customTypeController.text.trim()
                          : selectedType ?? '';
                      final goals = selectedGoals;
                      final duration = int.tryParse(_durationController.text.trim()) ?? 0;
                      final muscleGroups = _extractMuscleGroupsFromExercises(selectedExercises);

                      final List<WorkoutExercise> workoutExercises = selectedExercises.map((exercise) {
                        final Map<String, WorkoutMode> modes = {};

                        for (final goal in selectedGoals) {
                          final mode = exerciseModesByGoal[goal]?[exercise.id];
                          if (mode != null) {
                            modes[goal] = mode;
                          }
                        }

                        return WorkoutExercise(
                          exerciseId: exercise.id,
                          modes: modes,
                        );
                      }).toList();

                      // 2. Создаем объект Workout
                      final workout = Workout(
                        id: widget.existingWorkout?.id ?? '', // если редактируем, сохраняем ID
                        name: name,
                        tagline: tagline,
                        description: description,
                        level: level,
                        type: type,
                        targetGoals: goals,
                        muscleGroups: muscleGroups,
                        duration: duration,
                        isFavorite: widget.existingWorkout?.isFavorite ?? false,
                        exercises: workoutExercises,
                      );

                      // 3. Получаем uid
                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      if (uid == null) {
                        throw Exception('Пользователь не авторизован');
                      }

                      // 4. Сохраняем тренировку
                      if (widget.existingWorkout != null) {
                        await MyWorkoutRepository().updateWorkout(uid, workout.id, workout);
                      } else {
                        await MyWorkoutRepository().addWorkout(uid, workout);
                      }

                      // 5. Навигация или сообщение
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Тренировка успешно сохранена')),
                        );
                        Navigator.pop(context, true); // или перейти на экран с тренировками
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Ошибка: ${e.toString()}')),
                        );
                      }
                    }
                  }
                },
                child: const Text('Сохранить тренировку'),
              )
            ],
          ),
        ),
      ),
    );
  }

  List<String> _extractMuscleGroupsFromExercises(List<Exercise> exercises) {
    final Set<String> groups = {};
    for (final ex in exercises) {
      groups.addAll(ex.primaryMuscles);
      groups.addAll(ex.secondaryMuscles ?? []);
    }
    return groups.toList();
  }

  Widget _buildDropdownOrCustom({
    required String label,
    required List<String> items,
    required String? selectedItem,
    required bool customEnabled,
    required Function(String?) onChanged,
    required VoidCallback onToggleCustom,
    required TextEditingController customController,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        customEnabled
            ? TextFormField(
                controller: customController,
                decoration: const InputDecoration(hintText: 'Введите своё'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Заполните поле' : null,
              )
            : DropdownButtonFormField<String>(
                value: selectedItem,
                items: items
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e),
                        ))
                    .toList(),
                onChanged: onChanged,
                validator: (val) =>
                    val == null ? 'Выберите вариант или введите своё' : null,
              ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: onToggleCustom,
            child: Text(customEnabled ? 'Выбрать из списка' : 'Ввести своё'),
          ),
        )
      ],
    );
  }

  Widget _buildMultiSelectOrCustom() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Цели *'),
        if (customGoal)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _customGoalController,
                decoration: const InputDecoration(hintText: 'Введите цель'),
                validator: (val) {
                  final trimmed = val?.trim();
                  if ((trimmed == null || trimmed.isEmpty) && !selectedGoals.any((g) => !goals.contains(g))) {
                    return 'Укажите цель';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  final goal = _customGoalController.text.trim();
                  if (goal.isNotEmpty && !selectedGoals.contains(goal)) {
                    setState(() {
                      selectedGoals.add(goal);
                      _customGoalController.clear();
                    });
                  }
                },
                child: const Text('Добавить цель'),
              ),
              if (selectedGoals.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Wrap(
                    spacing: 8,
                    children: selectedGoals
                        .where((g) => !goals.contains(g))
                        .map((goal) => Chip(
                              label: Text(goal),
                              onDeleted: () {
                                setState(() {
                                  selectedGoals.remove(goal);
                                });
                              },
                            ))
                        .toList(),
                  ),
                ),
            ],
          )
        else
          Wrap(
            spacing: 8,
            children: goals.map((goal) {
              final selected = selectedGoals.contains(goal);
              return FilterChip(
                label: Text(goal),
                selected: selected,
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      selectedGoals.add(goal);
                    } else {
                      selectedGoals.remove(goal);
                    }
                  });
                },
              );
            }).toList(),
          ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              setState(() {
                customGoal = !customGoal;
                if (!customGoal) {
                  _customGoalController.clear();
                  // Очищаем из selectedGoals кастомную цель, если была
                  selectedGoals.removeWhere(
                      (goal) => !goals.contains(goal));
                }
              });
            },
            child: Text(customGoal ? 'Выбрать из списка' : 'Ввести своё'),
          ),
        )
      ],
    );
  }

  Widget _buildExerciseModesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: selectedExercises.map((exercise) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              exercise.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            ...selectedGoals.map((goal) {
              // Инициализация, если нужно
              exerciseModesByGoal.putIfAbsent(goal, () => {});
              exerciseModesByGoal[goal]!.putIfAbsent(exercise.id, () => WorkoutMode(sets: 0, reps: 0, restSeconds: 0));

              final mode = exerciseModesByGoal[goal]![exercise.id]!;

              return Padding(
                padding: const EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal, style: const TextStyle(fontWeight: FontWeight.w500)),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: mode.sets.toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Подходы'),
                            onChanged: (val) {
                              final parsed = int.tryParse(val);
                              if (parsed != null) {
                                final current = exerciseModesByGoal[goal]![exercise.id]!;
                                exerciseModesByGoal[goal]![exercise.id] = WorkoutMode(
                                  sets: parsed,
                                  reps: current.reps,
                                  restSeconds: current.restSeconds,
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: mode.reps.toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Повторы'),
                            onChanged: (val) {
                              final parsed = int.tryParse(val);
                              if (parsed != null) {
                                final current = exerciseModesByGoal[goal]![exercise.id]!;
                                exerciseModesByGoal[goal]![exercise.id] = WorkoutMode(
                                  sets: current.sets,
                                  reps: parsed,
                                  restSeconds: current.restSeconds,
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: mode.restSeconds.toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Отдых (сек)'),
                            onChanged: (val) {
                              final parsed = int.tryParse(val);
                              if (parsed != null) {
                                final current = exerciseModesByGoal[goal]![exercise.id]!;
                                exerciseModesByGoal[goal]![exercise.id] = WorkoutMode(
                                  sets: current.sets,
                                  reps: current.reps,
                                  restSeconds: parsed,
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      }).toList(),
    );
  }
}