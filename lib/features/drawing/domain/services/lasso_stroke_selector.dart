import '../entities/ink_point.dart';
import '../entities/ink_stroke.dart';

final class LassoStrokeSelector {
  const LassoStrokeSelector();

  Set<String> select({
    required List<InkStroke> strokes,
    required List<InkPoint> lassoPoints,
  }) {
    if (lassoPoints.length < 3) {
      return const {};
    }

    return strokes
        .where((stroke) => _strokeTouchesArea(stroke, lassoPoints))
        .map((stroke) => stroke.id)
        .toSet();
  }

  bool _strokeTouchesArea(InkStroke stroke, List<InkPoint> polygon) {
    return stroke.points.any((point) => _isInsidePolygon(point, polygon));
  }

  bool _isInsidePolygon(InkPoint point, List<InkPoint> polygon) {
    var isInside = false;
    var previousIndex = polygon.length - 1;

    for (var index = 0; index < polygon.length; index++) {
      final current = polygon[index];
      final previous = polygon[previousIndex];

      final crossesHorizontalRay =
          (current.y > point.y) != (previous.y > point.y);

      if (crossesHorizontalRay) {
        final intersectionX =
            (previous.x - current.x) *
                (point.y - current.y) /
                (previous.y - current.y) +
            current.x;

        if (point.x < intersectionX) {
          isInside = !isInside;
        }
      }

      previousIndex = index;
    }

    return isInside;
  }
}
