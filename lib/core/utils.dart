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