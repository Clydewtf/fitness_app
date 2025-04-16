import 'package:flutter/material.dart';
import '../../../data/models/exercise_model.dart';

class CreateWorkoutScreen extends StatefulWidget {
  const CreateWorkoutScreen({super.key});

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

  bool customLevel = false;
  bool customType = false;
  bool customGoal = false;

  final _customLevelController = TextEditingController();
  final _customTypeController = TextEditingController();
  final _customGoalController = TextEditingController();

  // Примерные варианты
  final levels = ['Новичок', 'Средний', 'Продвинутый'];
  final types = ['Силовая', 'Кардио', 'Растяжка', 'Плиометрика', 'Стронгмен',
      'Пауэрлифтинг', 'Тяжёлая атлетика', 'Кроссфит'];
  final goals = ['Поддержание формы', 'Набор массы', 'Сушка'];

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

              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // TODO: сохранить тренировку
                    print('Сохраняем...');
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
          TextFormField(
            controller: _customGoalController,
            decoration: const InputDecoration(hintText: 'Введите цель'),
            validator: (val) =>
                val == null || val.isEmpty ? 'Укажите цель' : null,
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
            onPressed: () => setState(() => customGoal = !customGoal),
            child: Text(customGoal ? 'Выбрать из списка' : 'Ввести своё'),
          ),
        )
      ],
    );
  }
}

class SelectedExercise {
  final Exercise exercise;
  final Map<String, ExerciseParams> parametersByGoal;

  SelectedExercise({
    required this.exercise,
    required this.parametersByGoal,
  });
}

class ExerciseParams {
  int sets;
  int reps;
  int restSeconds;

  ExerciseParams({
    required this.sets,
    required this.reps,
    required this.restSeconds,
  });
}