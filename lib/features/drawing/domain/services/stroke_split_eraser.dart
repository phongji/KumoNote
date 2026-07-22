import '../entities/ink_point.dart';
import '../entities/ink_stroke.dart';

final class StrokeSplitEraser {
  const StrokeSplitEraser();

  List<InkStroke> erase({
    required InkStroke stroke,
    required double x,
    required double y,
    required double eraserRadius,
    required String Function() createId,
  }) {
    if (stroke.points.isEmpty) {
      return const [];
    }

    final hitRadius = eraserRadius + (stroke.width / 2);
    final hitRadiusSquared = hitRadius * hitRadius;
    final remainingSegments = <List<InkPoint>>[];
    var currentSegment = <InkPoint>[];
    var removedAnyPoint = false;

    for (final point in stroke.points) {
      final deltaX = point.x - x;
      final deltaY = point.y - y;
      final isInsideEraser =
          ((deltaX * deltaX) + (deltaY * deltaY)) <= hitRadiusSquared;

      if (isInsideEraser) {
        removedAnyPoint = true;

        if (currentSegment.isNotEmpty) {
          remainingSegments.add(currentSegment);
          currentSegment = <InkPoint>[];
        }
      } else {
        currentSegment.add(point);
      }
    }

    if (currentSegment.isNotEmpty) {
      remainingSegments.add(currentSegment);
    }

    if (!removedAnyPoint) {
      return [stroke];
    }

    final result = <InkStroke>[];

    for (var index = 0; index < remainingSegments.length; index++) {
      final points = remainingSegments[index];

      if (points.isEmpty) {
        continue;
      }

      result.add(
        InkStroke(
          id: index == 0 ? stroke.id : createId(),
          pageId: stroke.pageId,
          tool: stroke.tool,
          colorValue: stroke.colorValue,
          width: stroke.width,
          opacity: stroke.opacity,
          points: points,
          createdAt: stroke.createdAt,
        ),
      );
    }

    return result;
  }
}
