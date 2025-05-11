import 'package:flutter/material.dart';

class FilterBottomSheet extends StatefulWidget {
  final String? selectedMuscleGroup;
  final String? selectedType;
  final String? selectedEquipment;
  final List<String> selectedLevels;
  final List<String> muscleGroups;
  final List<String> types;
  final List<String> equipment;
  final Function({
    String? muscleGroup,
    String? type,
    String? equipment,
    List<String>? levels,
  }) onApply;

  const FilterBottomSheet({
    super.key,
    required this.selectedMuscleGroup,
    required this.selectedType,
    required this.selectedEquipment,
    required this.selectedLevels,
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
  List<String> _selectedLevels = [];
  final _allLevels = ["Новичок", "Средний", "Продвинутый"];


  @override
  void initState() {
    super.initState();
    _selectedMuscleGroup = widget.selectedMuscleGroup ?? "Все";
    _selectedType = widget.selectedType ?? "Все";
    _selectedEquipment = widget.selectedEquipment ?? "Все";
    _selectedLevels = widget.selectedLevels.isEmpty
    ? List.from(_allLevels)
    : List.from(widget.selectedLevels);
  }

  @override
  Widget build(BuildContext context) {
    final muscleGroupItems = ["Все", ...widget.muscleGroups.toSet()];
    final typeItems = ["Все", ...widget.types.toSet()];
    final equipmentItems = ["Все", ...widget.equipment.toSet()];

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 16,
          left: 16,
          right: 16,
        ),
        child: SingleChildScrollView(
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

              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text("Уровень", style: TextStyle(fontSize: 16)),
                ),
              ),
              Wrap(
                spacing: 8,
                children: _allLevels.map((level) {
                  final isSelected = _selectedLevels.contains(level);
                  return FilterChip(
                    label: Text(level),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedLevels.add(level);
                        } else {
                          _selectedLevels.remove(level);
                        }
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      _selectedLevels.clear();
                      widget.onApply(
                        muscleGroup: null,
                        type: null,
                        equipment: null,
                        levels: null,
                      );
                      Navigator.pop(context);
                    },
                    child: const Text("Сбросить"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      widget.onApply(
                        muscleGroup: _selectedMuscleGroup == "Все" ? null : _selectedMuscleGroup,
                        type: _selectedType == "Все" ? null : _selectedType,
                        equipment: _selectedEquipment == "Все" ? null : _selectedEquipment,
                        levels: _selectedLevels.length == _allLevels.length ? null : _selectedLevels,
                      );
                      Navigator.pop(context);
                    },
                    child: const Text("Применить"),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
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