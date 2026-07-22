import '../../domain/entities/ink_point.dart';
import '../../domain/entities/ink_stroke.dart';

final class StrokeSelectionState {
  const StrokeSelectionState({
    this.lassoPoints = const [],
    this.selectedStrokeIds = const {},
    this.clipboardStrokes = const [],
    this.isDrawingLasso = false,
  });

  final List<InkPoint> lassoPoints;
  final Set<String> selectedStrokeIds;
  final List<InkStroke> clipboardStrokes;
  final bool isDrawingLasso;

  bool get hasSelection => selectedStrokeIds.isNotEmpty;

  bool get hasClipboard => clipboardStrokes.isNotEmpty;

  StrokeSelectionState copyWith({
    List<InkPoint>? lassoPoints,
    Set<String>? selectedStrokeIds,
    List<InkStroke>? clipboardStrokes,
    bool? isDrawingLasso,
  }) {
    return StrokeSelectionState(
      lassoPoints: lassoPoints ?? this.lassoPoints,
      selectedStrokeIds: selectedStrokeIds ?? this.selectedStrokeIds,
      clipboardStrokes: clipboardStrokes ?? this.clipboardStrokes,
      isDrawingLasso: isDrawingLasso ?? this.isDrawingLasso,
    );
  }

  StrokeSelectionState clearSelection() {
    return StrokeSelectionState(clipboardStrokes: clipboardStrokes);
  }

  StrokeSelectionState clearLasso() {
    return StrokeSelectionState(
      selectedStrokeIds: selectedStrokeIds,
      clipboardStrokes: clipboardStrokes,
    );
  }
}
