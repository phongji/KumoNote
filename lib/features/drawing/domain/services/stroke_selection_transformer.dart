// Copy all content into stroke_selection_transformer.dart.
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

    final center = _selectionCenter(strokes: strokes, selectedIds: selectedIds);

    if (center == null) {
      return strokes;
    }

    return strokes.map((stroke) {
      if (!selectedIds.contains(stroke.id)) {
        return stroke;
      }

      return stroke.scaleAround(
        centerX: center.x,
        centerY: center.y,
        scale: scale,
      );
    }).toList();
  }

  List<InkStroke> rotate({
    required List<InkStroke> strokes,
    required Set<String> selectedIds,
    required double angleRadians,
  }) {
    final center = _selectionCenter(strokes: strokes, selectedIds: selectedIds);

    if (center == null) {
      return strokes;
    }

    return strokes.map((stroke) {
      if (!selectedIds.contains(stroke.id)) {
        return stroke;
      }

      return stroke.rotateAround(
        centerX: center.x,
        centerY: center.y,
        angleRadians: angleRadians,
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

  _SelectionCenter? _selectionCenter({
    required List<InkStroke> strokes,
    required Set<String> selectedIds,
  }) {
    final points = strokes
        .where((stroke) => selectedIds.contains(stroke.id))
        .expand((stroke) => stroke.points)
        .toList();

    if (points.isEmpty) {
      return null;
    }

    final minimumX = points
        .map((point) => point.x)
        .reduce((first, second) => first < second ? first : second);
    final maximumX = points
        .map((point) => point.x)
        .reduce((first, second) => first > second ? first : second);
    final minimumY = points
        .map((point) => point.y)
        .reduce((first, second) => first < second ? first : second);
    final maximumY = points
        .map((point) => point.y)
        .reduce((first, second) => first > second ? first : second);

    return _SelectionCenter(
      x: (minimumX + maximumX) / 2,
      y: (minimumY + maximumY) / 2,
    );
  }
}

final class _SelectionCenter {
  const _SelectionCenter({required this.x, required this.y});

  final double x;
  final double y;
}
