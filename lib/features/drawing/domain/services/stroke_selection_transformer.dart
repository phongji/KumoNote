import '../entities/ink_stroke.dart';

final class StrokeSelectionTransformer {
  const StrokeSelectionTransformer();

  List<InkStroke> move({
    required List<InkStroke> strokes,
    required Set<String> selectedIds,
    required double deltaX,
    required double deltaY,
  }) {
    return strokes.map((stroke) {
      if (!selectedIds.contains(stroke.id)) {
        return stroke;
      }

      return stroke.translate(deltaX: deltaX, deltaY: deltaY);
    }).toList();
  }

  List<InkStroke> recolor({
    required List<InkStroke> strokes,
    required Set<String> selectedIds,
    required int colorValue,
  }) {
    return strokes.map((stroke) {
      if (!selectedIds.contains(stroke.id)) {
        return stroke;
      }

      return stroke.recolor(colorValue);
    }).toList();
  }

  List<InkStroke> scale({
    required List<InkStroke> strokes,
    required Set<String> selectedIds,
    required double scale,
  }) {
    if (scale <= 0) {
      return strokes;
    }

    final selectedStrokes = strokes
        .where((stroke) => selectedIds.contains(stroke.id))
        .toList();

    final selectedPoints = selectedStrokes
        .expand((stroke) => stroke.points)
        .toList();

    if (selectedPoints.isEmpty) {
      return strokes;
    }

    final minimumX = selectedPoints
        .map((point) => point.x)
        .reduce((first, second) => first < second ? first : second);
    final maximumX = selectedPoints
        .map((point) => point.x)
        .reduce((first, second) => first > second ? first : second);
    final minimumY = selectedPoints
        .map((point) => point.y)
        .reduce((first, second) => first < second ? first : second);
    final maximumY = selectedPoints
        .map((point) => point.y)
        .reduce((first, second) => first > second ? first : second);

    final centerX = (minimumX + maximumX) / 2;
    final centerY = (minimumY + maximumY) / 2;

    return strokes.map((stroke) {
      if (!selectedIds.contains(stroke.id)) {
        return stroke;
      }

      return stroke.scaleAround(
        centerX: centerX,
        centerY: centerY,
        scale: scale,
      );
    }).toList();
  }

  List<InkStroke> delete({
    required List<InkStroke> strokes,
    required Set<String> selectedIds,
  }) {
    return strokes.where((stroke) => !selectedIds.contains(stroke.id)).toList();
  }

  List<InkStroke> copy({
    required List<InkStroke> strokes,
    required Set<String> selectedIds,
  }) {
    return strokes.where((stroke) => selectedIds.contains(stroke.id)).toList();
  }

  List<InkStroke> paste({
    required List<InkStroke> strokes,
    required List<InkStroke> clipboard,
    required String Function() createId,
    double offsetX = 24,
    double offsetY = 24,
  }) {
    final pastedStrokes = clipboard.map((stroke) {
      return stroke.duplicate(
        newId: createId(),
        offsetX: offsetX,
        offsetY: offsetY,
      );
    });

    return [...strokes, ...pastedStrokes];
  }
}
