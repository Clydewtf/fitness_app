import 'package:flutter/material.dart';
import '../data/models/workout_log_model.dart';
import '../data/models/workout_session_model.dart';
import '../data/models/exercise_model.dart';
import '../data/repositories/exercise_repository.dart';
import 'locator.dart';

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



bool isLogComplete(WorkoutLog log, {required bool requireWeightsInSets}) {
  final hasMood = log.mood != null;
  final hasDifficulty = log.difficulty != null;
  final hasUserWeight = log.weight != null;

  final hasWeightInSets = log.exercises.any((exercise) {
    return exercise.sets.any((set) => set.weight != null);
  });

  final weightsOk = !requireWeightsInSets || hasWeightInSets;

  return hasMood && hasDifficulty && hasUserWeight && weightsOk;
}



class ExerciseNameText extends StatelessWidget {
  final String exerciseId;
  final TextStyle? style;

  const ExerciseNameText(this.exerciseId, {this.style, super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Exercise?>(
      future: locator<ExerciseRepository>().getExerciseById(exerciseId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text("Загрузка...", style: style?.copyWith(color: Colors.grey));
        }

        final exercise = snapshot.data;
        if (exercise != null) {
          return Text(exercise.name, style: style);
        } else {
          return Text("Упражнение не найдено", style: style?.copyWith(color: Colors.red));
        }
      },
    );
  }
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
  final double? value;
  final double step;
  final double? min;
  final double? max;
  final ValueChanged<double?> onChanged;
  final String? hintText;
  final bool isInteger;

  const IncrementableField({
    super.key,
    required this.label,
    required this.step,
    required this.onChanged,
    this.value,
    this.min,
    this.max,
    this.hintText,
    this.isInteger = false,
  });

  @override
  State<IncrementableField> createState() => _IncrementableFieldState();
}

class _IncrementableFieldState extends State<IncrementableField> {
  late TextEditingController _controller;
  double _currentValue = 0.0;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value ?? 0.0;
    _controller = TextEditingController(text: _formatValue(_currentValue));
  }

  String _formatValue(double value) {
    return widget.isInteger ? value.toInt().toString() : value.toString();
  }

  void _setValue(double newValue) {
    final clamped = newValue.clamp(widget.min ?? double.negativeInfinity, widget.max ?? double.infinity);
    setState(() {
      _currentValue = clamped;
      _controller.text = _formatValue(clamped);
    });
    widget.onChanged(clamped == 0.0 ? null : clamped);
  }

  @override
  void didUpdateWidget(covariant IncrementableField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newValue = widget.value ?? 0.0;
    if (newValue != _currentValue) {
      _currentValue = newValue;
      _controller.text = _formatValue(_currentValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.remove),
          onPressed: () => _setValue(_currentValue - widget.step),
          visualDensity: VisualDensity.compact,
        ),
        Expanded(
          child: TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
              final value = parsed ?? 0.0;
              _currentValue = value;
              widget.onChanged(value == 0.0 ? null : value);
            },
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => _setValue(_currentValue + widget.step),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}