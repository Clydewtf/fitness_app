import 'package:flutter/material.dart';

class MultiSelectDialog extends StatefulWidget {
  final List<String> options;
  const MultiSelectDialog(this.options, {super.key});

  @override
  _MultiSelectDialogState createState() => _MultiSelectDialogState();
}

class _MultiSelectDialogState extends State<MultiSelectDialog> {
  List<String> selectedItems = [];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Выберите дни"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: widget.options
            .map((day) => CheckboxListTile(
                  title: Text(day),
                  value: selectedItems.contains(day),
                  onChanged: (isChecked) {
                    setState(() {
                      if (isChecked!) {
                        selectedItems.add(day);
                      } else {
                        selectedItems.remove(day);
                      }
                    });
                  },
                ))
            .toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Отмена"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, selectedItems),
          child: const Text("ОК"),
        ),
      ],
    );
  }
}