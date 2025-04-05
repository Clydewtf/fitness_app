import 'package:flutter/material.dart';

class FilterBottomSheet extends StatefulWidget {
  final String? selectedMuscleGroup;
  final String? selectedType;
  final String? selectedEquipment;
  final List<String> muscleGroups;
  final List<String> types;
  final List<String> equipment;
  final Function({
    String? muscleGroup,
    String? type,
    String? equipment,
  }) onApply;

  const FilterBottomSheet({
    super.key,
    required this.selectedMuscleGroup,
    required this.selectedType,
    required this.selectedEquipment,
    required this.muscleGroups,
    required this.types,
    required this.equipment,
    required this.onApply,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  String? _selectedMuscleGroup;
  String? _selectedType;
  String? _selectedEquipment;

  @override
  void initState() {
    super.initState();
    _selectedMuscleGroup = widget.selectedMuscleGroup ?? "Все";
    _selectedType = widget.selectedType ?? "Все";
    _selectedEquipment = widget.selectedEquipment ?? "Все";
  }

  @override
  Widget build(BuildContext context) {
    final muscleGroupItems = ["Все", ...widget.muscleGroups.toSet()];
    final typeItems = ["Все", ...widget.types.toSet()];
    final equipmentItems = ["Все", ...widget.equipment.toSet()];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Фильтр упражнений",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          FilterDropdown(
            title: "Мышцы",
            value: _selectedMuscleGroup,
            items: muscleGroupItems,
            onChanged: (value) => setState(() => _selectedMuscleGroup = value),
          ),
          FilterDropdown(
            title: "Тип",
            value: _selectedType,
            items: typeItems,
            onChanged: (value) => setState(() => _selectedType = value),
          ),
          FilterDropdown(
            title: "Оборудование",
            value: _selectedEquipment,
            items: equipmentItems,
            onChanged: (value) => setState(() => _selectedEquipment = value),
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  widget.onApply(
                    muscleGroup: null,
                    type: null,
                    equipment: null,
                  );
                  Navigator.pop(context);
                },
                child: const Text("Сбросить"),
              ),
              ElevatedButton(
                onPressed: () {
                  widget.onApply(
                    muscleGroup: _selectedMuscleGroup,
                    type: _selectedType,
                    equipment: _selectedEquipment,
                  );
                  Navigator.pop(context);
                },
                child: const Text("Применить"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FilterDropdown extends StatelessWidget {
  final String title;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const FilterDropdown({
    super.key,
    required this.title,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        value: value ?? "Все",
        decoration: InputDecoration(labelText: title),
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}