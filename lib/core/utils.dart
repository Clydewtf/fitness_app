import 'package:flutter/material.dart';
import '../data/models/workout_session_model.dart';

int? findNextIncompleteExercise(List<WorkoutExerciseProgress> exercises, int justCompletedIndex) {
  final total = exercises.length;

  // Шагаем вперёд от только что выполненного
  for (int i = justCompletedIndex + 1; i < total; i++) {
    if (!_isDoneOrSkipped(exercises[i])) return i;
  }

  // Если не нашли — ищем сначала
  for (int i = 0; i < justCompletedIndex; i++) {
    if (!_isDoneOrSkipped(exercises[i])) return i;
  }

  // Всё завершено или скипнуто
  return null;
}

bool _isDoneOrSkipped(WorkoutExerciseProgress e) {
  return e.status == ExerciseStatus.done || e.status == ExerciseStatus.skipped;
}



class ImpulseBorderPainter extends CustomPainter {
  final double animationValue;
  final Paint _paint = Paint()
    ..color = Colors.deepOrange
    ..strokeWidth = 3
    ..style = PaintingStyle.stroke;

  ImpulseBorderPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final borderRadius = 20.0;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    canvas.drawRRect(rrect, Paint()..color = Colors.transparent); // для клипа

    final totalLength = 2 * (size.width + size.height);
    final pulseLength = 240.0; // длина импульса
    final offset = animationValue * totalLength;

    void drawPulse(double startOffset) {
      final endOffset = startOffset + pulseLength;
      final path = _extractPathSegment(rrect, startOffset, endOffset);
      if (path != null) {
        canvas.drawPath(path, _paint);
      }
    }

    drawPulse(offset);
    drawPulse((offset + totalLength / 2) % totalLength);
  }

  Path? _extractPathSegment(RRect rrect, double start, double end) {
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return null;

    final metric = metrics.first;
    final length = metric.length;

    start %= length;
    end %= length;

    if (end < start) {
      final firstPart = metric.extractPath(start, length);
      final secondPart = metric.extractPath(0, end);
      return Path()
        ..addPath(firstPart, Offset.zero)
        ..addPath(secondPart, Offset.zero);
    }

    return metric.extractPath(start, end);
  }

  @override
  bool shouldRepaint(covariant ImpulseBorderPainter oldDelegate) {
    return animationValue != oldDelegate.animationValue;
  }
}



class ShakeController {
  final ValueNotifier<double> notifier = ValueNotifier(0);

  void shake() async {
    const int shakes = 8;
    const double amplitude = 12;
    const duration = Duration(milliseconds: 70);

    for (int i = 0; i < shakes; i++) {
      notifier.value = i.isEven ? amplitude : -amplitude;
      await Future.delayed(duration);
    }

    notifier.value = 0;
  }
}

class ShakeWidget extends StatelessWidget {
  final Widget child;
  final ShakeController controller;

  const ShakeWidget({
    super.key,
    required this.child,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: controller.notifier,
      builder: (context, offset, child) {
        return Transform.translate(
          offset: Offset(offset, 0),
          child: child,
        );
      },
      child: child,
    );
  }
}



class IncrementableField extends StatefulWidget {
  final String label;
  final double value;
  final double step;
  final double? min;
  final double? max;
  final ValueChanged<double> onChanged;
  final String? hintText;
  final bool isInteger;

  const IncrementableField({
    super.key,
    required this.label,
    required this.value,
    required this.step,
    this.min,
    this.max,
    required this.onChanged,
    this.hintText,
    this.isInteger = false,
  });

  @override
  State<IncrementableField> createState() => _IncrementableFieldState();
}

class _IncrementableFieldState extends State<IncrementableField> {
  late TextEditingController _controller;
  late double _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
    _controller = TextEditingController(text: _formatValue(_currentValue));
  }

  String _formatValue(double value) {
    return widget.isInteger ? value.toInt().toString() : value.toString();
  }

  void _updateValue(double newValue) {
    final min = widget.min ?? double.negativeInfinity;
    final max = widget.max ?? double.infinity;
    newValue = newValue.clamp(min, max);
    setState(() {
      _currentValue = newValue;
      _controller.text = _formatValue(newValue);
    });
    widget.onChanged(newValue);
  }

  @override
  void didUpdateWidget(covariant IncrementableField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _currentValue) {
      _currentValue = widget.value;
      _controller.text = _formatValue(_currentValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.remove),
          onPressed: () => _updateValue(_currentValue - widget.step),
          visualDensity: VisualDensity.compact,
        ),
        Expanded(
          child: TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hintText,
              hintStyle: TextStyle(
                color: Colors.grey.withValues(alpha: 0.6),
              ),
              floatingLabelBehavior: FloatingLabelBehavior.always,
              border: const OutlineInputBorder(),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            ),
            onChanged: (val) {
              final parsed = double.tryParse(val.replaceAll(',', '.'));
              if (parsed != null) {
                _currentValue = parsed;
                widget.onChanged(parsed);
              }
            },
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => _updateValue(_currentValue + widget.step),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}