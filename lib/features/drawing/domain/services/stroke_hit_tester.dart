import 'dart:math' as math;

import '../entities/ink_point.dart';
import '../entities/ink_stroke.dart';

final class StrokeHitTester {
  const StrokeHitTester();

  InkStroke? findTopmost({
    required List<InkStroke> strokes,
    required double x,
    required double y,
    required double eraserRadius,
  }) {
    for (final stroke in strokes.reversed) {
      if (_isHit(stroke: stroke, x: x, y: y, eraserRadius: eraserRadius)) {
        return stroke;
      }
    }

    return null;
  }

  bool _isHit({
    required InkStroke stroke,
    required double x,
    required double y,
    required double eraserRadius,
  }) {
    if (stroke.points.isEmpty) {
      return false;
    }

    final hitRadius = eraserRadius + (stroke.width / 2);
    final hitRadiusSquared = hitRadius * hitRadius;

    if (stroke.points.length == 1) {
      final point = stroke.points.first;
      final deltaX = x - point.x;
      final deltaY = y - point.y;

      return ((deltaX * deltaX) + (deltaY * deltaY)) <= hitRadiusSquared;
    }

    for (var index = 1; index < stroke.points.length; index++) {
      final start = stroke.points[index - 1];
      final end = stroke.points[index];

      if (_distanceSquaredToSegment(x: x, y: y, start: start, end: end) <=
          hitRadiusSquared) {
        return true;
      }
    }

    return false;
  }

  double _distanceSquaredToSegment({
    required double x,
    required double y,
    required InkPoint start,
    required InkPoint end,
  }) {
    final segmentX = end.x - start.x;
    final segmentY = end.y - start.y;
    final segmentLengthSquared = (segmentX * segmentX) + (segmentY * segmentY);

    if (segmentLengthSquared == 0) {
      final deltaX = x - start.x;
      final deltaY = y - start.y;

      return (deltaX * deltaX) + (deltaY * deltaY);
    }

    final projection =
        (((x - start.x) * segmentX) + ((y - start.y) * segmentY)) /
        segmentLengthSquared;

    final clampedProjection = math.max(0.0, math.min(1.0, projection));

    final closestX = start.x + (clampedProjection * segmentX);
    final closestY = start.y + (clampedProjection * segmentY);
    final deltaX = x - closestX;
    final deltaY = y - closestY;

    return (deltaX * deltaX) + (deltaY * deltaY);
  }
}
