import '../../domain/entities/ink_stroke.dart';
import 'drawing_history_entry.dart';
import 'stroke_selection_state.dart';

enum EraserMode { partial, wholeStroke }

enum CanvasInteractionMode { ink, lasso }

final class DrawingState {
  DrawingState({
    required List<InkStroke> strokes,
    required List<DrawingHistoryEntry> undoHistory,
    required List<DrawingHistoryEntry> redoHistory,
    required this.selectedTool,
    required this.eraserMode,
    required this.colorValue,
    required this.strokeWidth,
    required this.opacity,
    this.interactionMode = CanvasInteractionMode.ink,
    this.selection = const StrokeSelectionState(),
    this.activeStroke,
    this.isSaving = false,
  }) : strokes = List.unmodifiable(strokes),
       undoHistory = List.unmodifiable(undoHistory),
       redoHistory = List.unmodifiable(redoHistory);

  factory DrawingState.initial() {
    return DrawingState(
      strokes: const [],
      undoHistory: const [],
      redoHistory: const [],
      selectedTool: InkTool.pen,
      eraserMode: EraserMode.partial,
      colorValue: 0xFF263238,
      strokeWidth: 2.5,
      opacity: 1,
    );
  }

  final List<InkStroke> strokes;
  final List<DrawingHistoryEntry> undoHistory;
  final List<DrawingHistoryEntry> redoHistory;
  final InkStroke? activeStroke;
  final InkTool selectedTool;
  final EraserMode eraserMode;
  final CanvasInteractionMode interactionMode;
  final StrokeSelectionState selection;
  final int colorValue;
  final double strokeWidth;
  final double opacity;
  final bool isSaving;

  bool get canUndo {
    return activeStroke == null && !isSaving && undoHistory.isNotEmpty;
  }

  bool get canRedo {
    return activeStroke == null && !isSaving && redoHistory.isNotEmpty;
  }

  bool get isLassoMode => interactionMode == CanvasInteractionMode.lasso;

  bool get hasSelection => selection.hasSelection;

  bool get hasClipboard => selection.hasClipboard;

  DrawingState copyWith({
    List<InkStroke>? strokes,
    List<DrawingHistoryEntry>? undoHistory,
    List<DrawingHistoryEntry>? redoHistory,
    InkStroke? activeStroke,
    bool clearActiveStroke = false,
    InkTool? selectedTool,
    EraserMode? eraserMode,
    CanvasInteractionMode? interactionMode,
    StrokeSelectionState? selection,
    int? colorValue,
    double? strokeWidth,
    double? opacity,
    bool? isSaving,
  }) {
    return DrawingState(
      strokes: strokes ?? this.strokes,
      undoHistory: undoHistory ?? this.undoHistory,
      redoHistory: redoHistory ?? this.redoHistory,
      activeStroke: clearActiveStroke
          ? null
          : activeStroke ?? this.activeStroke,
      selectedTool: selectedTool ?? this.selectedTool,
      eraserMode: eraserMode ?? this.eraserMode,
      interactionMode: interactionMode ?? this.interactionMode,
      selection: selection ?? this.selection,
      colorValue: colorValue ?? this.colorValue,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      opacity: opacity ?? this.opacity,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}
