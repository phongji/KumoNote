import 'package:flutter/material.dart';

import '../../domain/entities/ink_stroke.dart';

final class InkPainter extends CustomPainter {
  const InkPainter({required this.strokes, required this.activeStroke});

  final List<InkStroke> strokes;
  final InkStroke? activeStroke;

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      _paintStroke(canvas, stroke);
    }

    final currentStroke = activeStroke;

    if (currentStroke != null) {
      _paintStroke(canvas, currentStroke);
    }
  }

  void _paintStroke(Canvas canvas, InkStroke stroke) {
    if (stroke.points.isEmpty || stroke.tool == InkTool.eraser) {
      return;
    }

    final color = Color(stroke.colorValue).withValues(alpha: stroke.opacity);

    if (stroke.tool == InkTool.highlighter) {
      _paintHighlighter(canvas: canvas, stroke: stroke, color: color);
      return;
    }

    if (stroke.points.length == 1) {
      final point = stroke.points.first;
      final radius = _widthForPressure(stroke.width, point.pressure) / 2;

      canvas.drawCircle(
        Offset(point.x, point.y),
        radius,
        Paint()..color = color,
      );

      return;
    }

    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (var index = 1; index < stroke.points.length; index++) {
      final previous = stroke.points[index - 1];
      final current = stroke.points[index];
      final averagePressure = (previous.pressure + current.pressure) / 2;

      paint.strokeWidth = _widthForPressure(stroke.width, averagePressure);

      canvas.drawLine(
        Offset(previous.x, previous.y),
        Offset(current.x, current.y),
        paint,
      );
    }
  }

  void _paintHighlighter({
    required Canvas canvas,
    required InkStroke stroke,
    required Color color,
  }) {
    final firstPoint = stroke.points.first;
    final path = Path()..moveTo(firstPoint.x, firstPoint.y);

    for (final point in stroke.points.skip(1)) {
      path.lineTo(point.x, point.y);
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = stroke.width
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (stroke.points.length == 1) {
      canvas.drawCircle(
        Offset(firstPoint.x, firstPoint.y),
        stroke.width / 2,
        paint..style = PaintingStyle.fill,
      );
      return;
    }

    canvas.drawPath(path, paint);
  }

  double _widthForPressure(double width, double pressure) {
    const minimumPressureFactor = 0.45;
    final normalizedPressure = pressure.clamp(0.0, 1.0);

    return width *
        (minimumPressureFactor +
            ((1 - minimumPressureFactor) * normalizedPressure));
  }

  @override
  bool shouldRepaint(covariant InkPainter oldDelegate) {
    return strokes != oldDelegate.strokes ||
        activeStroke != oldDelegate.activeStroke;
  }
}
