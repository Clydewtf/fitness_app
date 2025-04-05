import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/workout_bloc/exercise_event.dart';
import '../../widgets/workouts/exercise_card.dart';
import '../../../logic/workout_bloc/exercise_bloc.dart';
import '../../../logic/workout_bloc/exercise_state.dart';
import '../../widgets/workouts/filter_bottom_sheet.dart';

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

  void _onFilterChanged({
    String? muscleGroup,
    String? type,
    String? equipment,
  }) {
    setState(() {
      selectedMuscleGroup = muscleGroup == "Все" ? null : muscleGroup;
      selectedType = type == "Все" ? null : type;
      selectedEquipment = equipment == "Все" ? null : equipment;
    });

    context.read<ExerciseBloc>().add(
      FilterExercises(
        muscleGroup: selectedMuscleGroup,
        type: selectedType,
        equipment: selectedEquipment,
      ),
    );
  }

  void _openFilterSheet(BuildContext context, List<String> muscleGroups, List<String> types, List<String> equipment) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return FilterBottomSheet(
          selectedMuscleGroup: selectedMuscleGroup,
          selectedType: selectedType,
          selectedEquipment: selectedEquipment,
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
            key: ValueKey('$selectedMuscleGroup|$selectedType|$selectedEquipment'),
            selectedMuscleGroup: selectedMuscleGroup,
            selectedType: selectedType,
            selectedEquipment: selectedEquipment,
            onFilterChanged: _onFilterChanged,
            onOpenFilter: _openFilterSheet,
          )
        ],
      ),
    );
  }
}

// === Заглушка вкладки тренировок ===
class WorkoutsTab extends StatelessWidget {
  const WorkoutsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Здесь будут тренировки'));
  }
}

class ExercisesTab extends StatefulWidget {
  final String? selectedMuscleGroup;
  final String? selectedType;
  final String? selectedEquipment;
  final void Function({
    String? muscleGroup,
    String? type,
    String? equipment,
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
    required this.onFilterChanged,
    required this.onOpenFilter,
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
        searchQuery: query,
      ),
    );
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
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExerciseBloc, ExerciseState>(
      builder: (context, state) {
        if (state is ExerciseLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is ExerciseLoaded) {
          final allExercises = state.allExercises;
          final filtered = state.filteredExercises;

          final muscleGroups = allExercises.map((e) => e.muscleGroup).toSet().toList();
          final types = allExercises.map((e) => e.type).toSet().toList();
          final equipment = allExercises.map((e) => e.equipment).toSet().toList();

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
                            return ExerciseCard(exercise: exercise);
                          },
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