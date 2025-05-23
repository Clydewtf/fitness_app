import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/exercise_model.dart';
import '../../../logic/workout_bloc/exercise_event.dart';
import '../../../logic/workout_bloc/my_workout_bloc.dart';
import '../../../logic/workout_bloc/my_workout_event.dart';
import '../../../logic/workout_bloc/my_workout_state.dart';
import '../../../services/auth_service.dart';
import '../../widgets/workouts/exercise_card.dart';
import '../../../logic/workout_bloc/exercise_bloc.dart';
import '../../../logic/workout_bloc/exercise_state.dart';
import '../../widgets/workouts/filter_bottom_sheet.dart';
import '../../../logic/workout_bloc/workout_bloc.dart';
import '../../../logic/workout_bloc/workout_state.dart';
import '../../widgets/workouts/workout_card.dart';
import '../workouts/workout_create_screen.dart';
import 'my_workouts_screen.dart';
import 'all_recommended_screen.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? selectedMuscleGroup;
  String? selectedType;
  String? selectedEquipment;
  List<String> selectedLevels = [];

  void _onFilterChanged({
    String? muscleGroup,
    String? type,
    String? equipment,
    List<String>? levels,
  }) {
    setState(() {
      selectedMuscleGroup = muscleGroup == "Все" ? null : muscleGroup;
      selectedType = type == "Все" ? null : type;
      selectedEquipment = equipment == "Все" ? null : equipment;
      selectedLevels = levels ?? [];
    });

    context.read<ExerciseBloc>().add(
      FilterExercises(
        muscleGroup: selectedMuscleGroup,
        type: selectedType,
        equipment: selectedEquipment,
        levels: selectedLevels.isEmpty ? null : selectedLevels,
      ),
    );
  }

  void _openFilterSheet(BuildContext context, List<String> muscleGroups, List<String> types, List<String> equipment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return FilterBottomSheet(
          selectedMuscleGroup: selectedMuscleGroup,
          selectedType: selectedType,
          selectedEquipment: selectedEquipment,
          selectedLevels: selectedLevels, 
          muscleGroups: muscleGroups,
          types: types,
          equipment: equipment,
          onApply: _onFilterChanged,
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Тренировки'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Тренировки'),
            Tab(text: 'Упражнения'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const WorkoutsTab(),
          ExercisesTab(
            key: ValueKey('$selectedMuscleGroup|$selectedType|$selectedEquipment|${selectedLevels.join(",")}'),
            selectedMuscleGroup: selectedMuscleGroup,
            selectedType: selectedType,
            selectedEquipment: selectedEquipment,
            selectedLevels: selectedLevels,
            onFilterChanged: _onFilterChanged,
            onOpenFilter: _openFilterSheet,
          )
        ],
      ),
    );
  }
}

class WorkoutsTab extends StatefulWidget {
  const WorkoutsTab({super.key});

  @override
  State<WorkoutsTab> createState() => _WorkoutsTabState();
}

class _WorkoutsTabState extends State<WorkoutsTab> {
  bool showAllFavorites = false;
  final PageController _pageController = PageController(viewportFraction: 1.0);
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rootContext = context;

    return BlocBuilder<MyWorkoutBloc, MyWorkoutState>(
      builder: (context, myWorkoutState) {
        if (myWorkoutState is MyWorkoutLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (myWorkoutState is MyWorkoutLoaded) {
          final myFavorites = myWorkoutState.workouts.where((w) => w.isFavorite).toList();

          return BlocBuilder<WorkoutBloc, WorkoutState>(
            builder: (context, state) {
              if (state is WorkoutLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is WorkoutLoaded) {
                final all = state.workouts;
                final globalFavorites = all.where((w) => w.isFavorite).toList();
                final recommended = all.where((w) => !w.isFavorite).toList();
                final previewCount = 4;
                final previewRecommended = recommended.take(previewCount).toList();

                final favorites = [
                  ...globalFavorites.map((w) => (w, false)),
                  ...myFavorites.map((w) => (w, true)),
                ];

                // 🛠 Защита от выхода за пределы
                if (_currentPage >= favorites.length) { 
                  _currentPage = 0;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_pageController.hasClients) {
                      _pageController.jumpToPage(0);
                    }
                  });
                }

                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    16 + MediaQuery.of(context).padding.bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ⭐️ Избранные тренировки
                      if (favorites.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Избранные", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  showAllFavorites = !showAllFavorites;
                                  if (!showAllFavorites) {
                                    _currentPage = 0;
                                    // Сбрасываем страницу после того как UI перестроится
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      if (_pageController.hasClients) {
                                        _pageController.jumpToPage(0);
                                      }
                                    });
                                  }
                                });
                              },
                              child: Text(showAllFavorites ? "Свернуть" : "Развернуть"),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (showAllFavorites)
                          // 👉 Вертикальный список
                          Column(
                            children: favorites.map((entry) {
                              final workout = entry.$1;
                              final isMyWorkout = entry.$2;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: WorkoutCard(
                                  workout: workout,
                                  isMyWorkout: isMyWorkout,
                                ),
                              );
                            }).toList(),
                          )
                        else
                          // 👉 Карусель
                          Builder(
                            builder: (context) {
                              final screenWidth = MediaQuery.of(context).size.width;
                              final cardWidth = screenWidth * 0.85;
                              final aspectRatio = 3 / 2;
                              final cardHeight = cardWidth / aspectRatio;

                              return SizedBox(
                                height: cardHeight + 12,
                                child: PageView.builder(
                                  controller: _pageController,
                                  itemCount: favorites.length,
                                  onPageChanged: (index) {
                                    setState(() => _currentPage = index);
                                  },
                                  itemBuilder: (context, index) {
                                    final workout = favorites[index].$1;
                                    final isMyWorkout = favorites[index].$2;

                                    return WorkoutCard(
                                      workout: workout,
                                      isMyWorkout: isMyWorkout,
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        if (!showAllFavorites && favorites.length > 1)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(favorites.length, (index) {
                                final isVisible = (index - _currentPage).abs() <= 1;
                                if (!isVisible) return const SizedBox.shrink();

                                final isActive = index == _currentPage;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  width: isActive ? 10 : 8,
                                  height: isActive ? 10 : 8,
                                  decoration: BoxDecoration(
                                    color: isActive ? Colors.blueAccent : Colors.grey[400],
                                    shape: BoxShape.circle,
                                  ),
                                );
                              }),
                            ),
                          )
                        else
                          const SizedBox(height: 24),
                      ],

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Рекомендованные",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              if (recommended.length > previewCount)
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => MultiBlocProvider(
                                          providers: [
                                            BlocProvider.value(value: context.read<WorkoutBloc>()),
                                            BlocProvider.value(value: context.read<MyWorkoutBloc>()),
                                            BlocProvider.value(value: context.read<ExerciseBloc>()),
                                          ],
                                          child: AllRecommendedScreen(workouts: recommended),
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text("Показать все"),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...previewRecommended.map(
                            (workout) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: WorkoutCard(workout: workout),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 🔸 Мои тренировки
                      ElevatedButton.icon(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) {
                                return MultiBlocProvider(
                                  providers: [
                                    BlocProvider.value(value: rootContext.read<WorkoutBloc>()),
                                    BlocProvider.value(value: rootContext.read<MyWorkoutBloc>()),
                                    BlocProvider.value(value: rootContext.read<ExerciseBloc>()),
                                  ],
                                  child: const MyWorkoutsScreen(),
                                );
                              },
                            ),
                          );
                        },
                        icon: const Icon(Icons.list_alt_rounded),
                        label: const Text("Мои тренировки"),
                        style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                      ),
                      const SizedBox(height: 12),

                      // ➕ Создать тренировку
                      OutlinedButton.icon(
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
                        icon: const Icon(Icons.add_rounded),
                        label: const Text("Создать тренировку"),
                        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                      ),
                    ],
                  ),
                );
              } else if (state is WorkoutError) {
                return Center(child: Text("Ошибка: ${state.message}"));
              } else {
                return const SizedBox.shrink();
              }
            },
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }
}

class ExercisesTab extends StatefulWidget {
  final bool isSelectionMode;
  final List<Exercise> initiallySelected;
  final void Function(List<Exercise>)? onSelectionDone;
  final String? selectedMuscleGroup;
  final String? selectedType;
  final String? selectedEquipment;  
  final List<String> selectedLevels;
  final void Function({
    String? muscleGroup,
    String? type,
    String? equipment,
    List<String>? levels,
  }) onFilterChanged;
  final void Function(
    BuildContext context,
    List<String> muscleGroups,
    List<String> types,
    List<String> equipment,
  ) onOpenFilter;

  const ExercisesTab({
    super.key,
    required this.selectedMuscleGroup,
    required this.selectedType,
    required this.selectedEquipment,
    required this.selectedLevels,
    required this.onFilterChanged,
    required this.onOpenFilter,
    this.isSelectionMode = false,
    this.initiallySelected = const [],
    this.onSelectionDone,
  });

  @override
  State<ExercisesTab> createState() => _ExercisesTabState();
}

class _ExercisesTabState extends State<ExercisesTab> {
  final TextEditingController _searchController = TextEditingController();

  void _onSearchChanged(String query) {
    context.read<ExerciseBloc>().add(
      FilterExercises(
        muscleGroup: widget.selectedMuscleGroup,
        type: widget.selectedType,
        equipment: widget.selectedEquipment,
        levels: widget.selectedLevels.isEmpty ? null : widget.selectedLevels,
        searchQuery: query,
      ),
    );
  }
  
  late List<Exercise> selectedExercises = [];

  @override
  void initState() {
    super.initState();
    selectedExercises = List.from(widget.initiallySelected);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int _getFilterCount() {
    int count = 0;
    if (widget.selectedMuscleGroup != null) count++;
    if (widget.selectedType != null) count++;
    if (widget.selectedEquipment != null) count++;
    if (widget.selectedLevels.isNotEmpty && widget.selectedLevels.length != 3) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: BlocBuilder<ExerciseBloc, ExerciseState>(
        builder: (context, state) {
          if (state is ExerciseLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ExerciseLoaded) {
            final allExercises = state.allExercises;
            final filtered = state.filteredExercises;

            // 🔹 Собираем уникальные мышцы (основные + второстепенные)
            final muscleGroups = allExercises
                .expand((e) => [...e.primaryMuscles, ...(e.secondaryMuscles ?? [])])
                .whereType<String>()
                .where((m) => m.trim().isNotEmpty)
                .toSet()
                .toList()
              ..sort();

            // 🔹 Уникальные типы и оборудование
            final types = allExercises.map((e) => e.type).whereType<String>().toSet().toList()..sort();
            final equipment = allExercises.map((e) => e.equipment).whereType<String>().toSet().toList()..sort();

            return Scaffold(
              appBar: AppBar(
                title: const Text('Упражнения'),
                actions: [
                  _FilterBadgeIcon(
                    filterCount: _getFilterCount(),
                    onPressed: () {
                      widget.onOpenFilter(context, muscleGroups, types, equipment);
                    },
                  ),
                ],
              ),
              body: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Поиск упражнения...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(child: Text("Нет упражнений по выбранным фильтрам"))
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final exercise = filtered[index];
                              if (widget.isSelectionMode) {
                                final isSelected = selectedExercises.any((e) => e.id == exercise.id);
                                return SelectableExerciseCard(
                                  exercise: exercise,
                                  isSelected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        selectedExercises.add(exercise);
                                      } else {
                                        selectedExercises.removeWhere((e) => e.id == exercise.id);
                                      }
                                    });
                                  },
                                );
                              } else {
                                return ExerciseCard(exercise: exercise);
                              }
                            },
                          ),
                  ),
                  if (widget.isSelectionMode)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          widget.onSelectionDone?.call(selectedExercises);
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Готово'),
                      ),
                    ),
                ],
              ),
            );
          } else if (state is ExerciseError) {
            return Center(child: Text('Ошибка: ${state.message}'));
          } else {
            return const SizedBox.shrink(); // fallback
          }
        },
      ),
    );
  }
}

class _FilterBadgeIcon extends StatelessWidget {
  final int filterCount;
  final VoidCallback onPressed;

  const _FilterBadgeIcon({
    required this.filterCount,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: onPressed,
        ),
        Positioned(
          right: 4,
          top: 4,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 250),
            scale: filterCount > 0 ? 1 : 0,
            curve: Curves.easeOutBack,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: filterCount > 0 ? 1 : 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '$filterCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}