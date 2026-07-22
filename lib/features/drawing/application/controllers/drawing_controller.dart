// Complete drawing controller for Kumo Notes.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/ink_point.dart';
import '../../domain/entities/ink_stroke.dart';
import '../../domain/services/lasso_stroke_selector.dart';
import '../../domain/services/stroke_hit_tester.dart';
import '../../domain/services/stroke_split_eraser.dart';
import '../../domain/services/stroke_selection_transformer.dart';
import '../providers/drawing_providers.dart';
import '../state/drawing_history_entry.dart';
import '../state/drawing_state.dart';

final drawingControllerProvider =
    AsyncNotifierProvider.family<DrawingController, DrawingState, String>(
      DrawingController.new,
    );

final class DrawingController extends AsyncNotifier<DrawingState> {
  DrawingController(this._pageId);

  static const _minimumPointDistanceSquared = 0.36;

  final Uuid _uuid = const Uuid();
  final StrokeHitTester _hitTester = const StrokeHitTester();
  final LassoStrokeSelector _lassoSelector = const LassoStrokeSelector();
  final StrokeSplitEraser _splitEraser = const StrokeSplitEraser();
  final StrokeSelectionTransformer _selectionTransformer =
      const StrokeSelectionTransformer();
  final Set<String> _pendingEraseIds = {};
  final String _pageId;
  List<InkStroke>? _selectionDragBeforeStrokes;
  double? _selectionDragLastX;
  double? _selectionDragLastY;
  bool _selectionDragMoved = false;
  List<InkStroke>? _selectionResizeBeforeStrokes;
  double? _selectionResizeLastDistance;
  bool _selectionResizeChanged = false;

  @override
  Future<DrawingState> build() async {
    final strokes = await ref.read(inkRepositoryProvider).getStrokes(_pageId);

    return DrawingState.initial().copyWith(
      strokes: strokes,
      undoHistory: _createInitialHistory(strokes),
    );
  }

  void startStroke({
    required double x,
    required double y,
    required double pressure,
    required int elapsedMicroseconds,
  }) {
    final current = state.requireValue;

    if (current.selectedTool == InkTool.eraser) {
      unawaited(_eraseAt(x: x, y: y, eraserRadius: current.strokeWidth / 2));
      return;
    }

    final stroke = InkStroke(
      id: _uuid.v4(),
      pageId: _pageId,
      tool: current.selectedTool,
      colorValue: current.colorValue,
      width: current.strokeWidth,
      opacity: current.opacity,
      points: [
        InkPoint(
          x: x,
          y: y,
          pressure: pressure.clamp(0.0, 1.0).toDouble(),
          elapsedMicroseconds: elapsedMicroseconds,
        ),
      ],
      createdAt: DateTime.now().toUtc(),
    );

    state = AsyncData(
      current.copyWith(
        activeStroke: stroke,
        selection: current.selection.clearSelection(),
      ),
    );
  }

  void addPoint({
    required double x,
    required double y,
    required double pressure,
    required int elapsedMicroseconds,
  }) {
    final current = state.requireValue;

    if (current.selectedTool == InkTool.eraser) {
      unawaited(_eraseAt(x: x, y: y, eraserRadius: current.strokeWidth / 2));
      return;
    }

    final activeStroke = current.activeStroke;

    if (activeStroke == null) {
      return;
    }

    final point = InkPoint(
      x: x,
      y: y,
      pressure: pressure.clamp(0.0, 1.0).toDouble(),
      elapsedMicroseconds: elapsedMicroseconds,
    );

    if (activeStroke.points.last.distanceSquaredTo(point) <
        _minimumPointDistanceSquared) {
      return;
    }

    state = AsyncData(
      current.copyWith(activeStroke: activeStroke.addPoint(point)),
    );
  }

  void straightenActiveStroke() {
    final current = state.requireValue;
    final activeStroke = current.activeStroke;

    if (activeStroke == null ||
        activeStroke.points.length < 2 ||
        activeStroke.tool == InkTool.eraser) {
      return;
    }

    final straightStroke = activeStroke.replacePoints([
      activeStroke.points.first,
      activeStroke.points.last,
    ]);

    state = AsyncData(current.copyWith(activeStroke: straightStroke));
  }

  Future<void> endStroke() async {
    final current = state.requireValue;
    final activeStroke = current.activeStroke;

    if (activeStroke == null || activeStroke.isEmpty) {
      return;
    }

    final updatedStrokes = [...current.strokes, activeStroke];

    final historyEntry = DrawingHistoryEntry(
      beforeStrokes: current.strokes,
      afterStrokes: updatedStrokes,
    );

    state = AsyncData(
      current.copyWith(
        strokes: updatedStrokes,
        undoHistory: [...current.undoHistory, historyEntry],
        redoHistory: const [],
        clearActiveStroke: true,
        isSaving: true,
      ),
    );

    try {
      await ref.read(inkRepositoryProvider).save(activeStroke);
      _finishSaving();
    } catch (_) {
      state = AsyncError(
        StateError('Unable to save the stroke.'),
        StackTrace.current,
      );
    }
  }

  Future<void> _eraseAt({
    required double x,
    required double y,
    required double eraserRadius,
  }) async {
    final current = state.requireValue;

    if (current.isSaving) {
      return;
    }

    final hitStroke = _hitTester.findTopmost(
      strokes: current.strokes,
      x: x,
      y: y,
      eraserRadius: eraserRadius,
    );

    if (hitStroke == null || _pendingEraseIds.contains(hitStroke.id)) {
      return;
    }

    _pendingEraseIds.add(hitStroke.id);

    final hitIndex = current.strokes.indexWhere(
      (stroke) => stroke.id == hitStroke.id,
    );

    final replacementStrokes = switch (current.eraserMode) {
      EraserMode.partial => _splitEraser.erase(
        stroke: hitStroke,
        x: x,
        y: y,
        eraserRadius: eraserRadius,
        createId: _uuid.v4,
      ),
      EraserMode.wholeStroke => <InkStroke>[],
    };

    final unchanged =
        replacementStrokes.length == 1 &&
        identical(replacementStrokes.first, hitStroke);

    if (unchanged) {
      _pendingEraseIds.remove(hitStroke.id);
      return;
    }

    final updatedStrokes = [
      ...current.strokes.take(hitIndex),
      ...replacementStrokes,
      ...current.strokes.skip(hitIndex + 1),
    ];

    final historyEntry = DrawingHistoryEntry(
      beforeStrokes: current.strokes,
      afterStrokes: updatedStrokes,
    );

    state = AsyncData(
      current.copyWith(
        strokes: updatedStrokes,
        undoHistory: [...current.undoHistory, historyEntry],
        redoHistory: const [],
        selection: current.selection.clearSelection(),
        clearActiveStroke: true,
        isSaving: true,
      ),
    );

    try {
      await _persistHistoryState(errorMessage: 'Unable to erase the stroke.');
    } finally {
      _pendingEraseIds.remove(hitStroke.id);
    }
  }

  void beginLasso({
    required double x,
    required double y,
    required int elapsedMicroseconds,
  }) {
    final current = state.requireValue;

    final firstPoint = InkPoint(
      x: x,
      y: y,
      pressure: 1,
      elapsedMicroseconds: elapsedMicroseconds,
    );

    state = AsyncData(
      current.copyWith(
        selection: current.selection.copyWith(
          lassoPoints: [firstPoint],
          selectedStrokeIds: const {},
          isDrawingLasso: true,
        ),
        clearActiveStroke: true,
      ),
    );
  }

  void addLassoPoint({
    required double x,
    required double y,
    required int elapsedMicroseconds,
  }) {
    final current = state.requireValue;
    final selection = current.selection;

    if (!selection.isDrawingLasso || selection.lassoPoints.isEmpty) {
      return;
    }

    final point = InkPoint(
      x: x,
      y: y,
      pressure: 1,
      elapsedMicroseconds: elapsedMicroseconds,
    );

    if (selection.lassoPoints.last.distanceSquaredTo(point) <
        _minimumPointDistanceSquared) {
      return;
    }

    state = AsyncData(
      current.copyWith(
        selection: selection.copyWith(
          lassoPoints: [...selection.lassoPoints, point],
        ),
      ),
    );
  }

  void endLasso() {
    final current = state.requireValue;
    final selection = current.selection;

    if (!selection.isDrawingLasso) {
      return;
    }

    final selectedIds = _lassoSelector.select(
      strokes: current.strokes,
      lassoPoints: selection.lassoPoints,
    );

    state = AsyncData(
      current.copyWith(
        selection: selection.copyWith(
          selectedStrokeIds: selectedIds,
          isDrawingLasso: false,
        ),
      ),
    );
  }

  void clearSelection() {
    final current = state.requireValue;

    state = AsyncData(
      current.copyWith(selection: current.selection.clearSelection()),
    );
  }

  void beginSelectionDrag({required double x, required double y}) {
    final current = state.requireValue;

    if (current.isSaving || !current.hasSelection) {
      return;
    }

    _selectionDragBeforeStrokes = current.strokes;
    _selectionDragLastX = x;
    _selectionDragLastY = y;
    _selectionDragMoved = false;
  }

  void updateSelectionDrag({required double x, required double y}) {
    final lastX = _selectionDragLastX;
    final lastY = _selectionDragLastY;

    if (lastX == null || lastY == null) {
      return;
    }

    final deltaX = x - lastX;
    final deltaY = y - lastY;

    if (deltaX == 0 && deltaY == 0) {
      return;
    }

    final current = state.requireValue;
    final updatedStrokes = _selectionTransformer.move(
      strokes: current.strokes,
      selectedIds: current.selection.selectedStrokeIds,
      deltaX: deltaX,
      deltaY: deltaY,
    );

    _selectionDragLastX = x;
    _selectionDragLastY = y;
    _selectionDragMoved = true;

    state = AsyncData(current.copyWith(strokes: updatedStrokes));
  }

  Future<void> endSelectionDrag() async {
    final beforeStrokes = _selectionDragBeforeStrokes;
    final moved = _selectionDragMoved;

    _selectionDragBeforeStrokes = null;
    _selectionDragLastX = null;
    _selectionDragLastY = null;
    _selectionDragMoved = false;

    if (beforeStrokes == null || !moved) {
      return;
    }

    final current = state.requireValue;
    final historyEntry = DrawingHistoryEntry(
      beforeStrokes: beforeStrokes,
      afterStrokes: current.strokes,
    );

    state = AsyncData(
      current.copyWith(
        undoHistory: [...current.undoHistory, historyEntry],
        redoHistory: const [],
        isSaving: true,
      ),
    );

    await _persistHistoryState(
      errorMessage: 'Unable to move the selected strokes.',
    );
  }

  void beginSelectionResize({required double distance}) {
    final current = state.requireValue;

    if (current.isSaving || !current.hasSelection || distance <= 0) {
      return;
    }

    _selectionResizeBeforeStrokes = current.strokes;
    _selectionResizeLastDistance = distance;
    _selectionResizeChanged = false;
  }

  void updateSelectionResize({required double distance}) {
    final lastDistance = _selectionResizeLastDistance;

    if (lastDistance == null || lastDistance <= 0 || distance <= 0) {
      return;
    }

    final scale = distance / lastDistance;

    if ((scale - 1).abs() < 0.001) {
      return;
    }

    final current = state.requireValue;
    final updatedStrokes = _selectionTransformer.scale(
      strokes: current.strokes,
      selectedIds: current.selection.selectedStrokeIds,
      scale: scale,
    );

    _selectionResizeLastDistance = distance;
    _selectionResizeChanged = true;

    state = AsyncData(current.copyWith(strokes: updatedStrokes));
  }

  Future<void> endSelectionResize() async {
    final beforeStrokes = _selectionResizeBeforeStrokes;
    final changed = _selectionResizeChanged;

    _selectionResizeBeforeStrokes = null;
    _selectionResizeLastDistance = null;
    _selectionResizeChanged = false;

    if (beforeStrokes == null || !changed) {
      return;
    }

    final current = state.requireValue;
    final historyEntry = DrawingHistoryEntry(
      beforeStrokes: beforeStrokes,
      afterStrokes: current.strokes,
    );

    state = AsyncData(
      current.copyWith(
        undoHistory: [...current.undoHistory, historyEntry],
        redoHistory: const [],
        isSaving: true,
      ),
    );

    await _persistHistoryState(
      errorMessage: 'Unable to resize the selected strokes.',
    );
  }

  Future<void> moveSelection({
    required double deltaX,
    required double deltaY,
  }) async {
    final current = state.requireValue;
    final selectedIds = current.selection.selectedStrokeIds;

    if (current.isSaving || selectedIds.isEmpty) {
      return;
    }

    final updatedStrokes = _selectionTransformer.move(
      strokes: current.strokes,
      selectedIds: selectedIds,
      deltaX: deltaX,
      deltaY: deltaY,
    );

    await _commitSelectionChange(
      beforeStrokes: current.strokes,
      updatedStrokes: updatedStrokes,
      errorMessage: 'Unable to move the selected strokes.',
    );
  }

  Future<void> scaleSelection(double scale) async {
    final current = state.requireValue;
    final selectedIds = current.selection.selectedStrokeIds;

    if (current.isSaving || selectedIds.isEmpty || scale <= 0) {
      return;
    }

    final updatedStrokes = _selectionTransformer.scale(
      strokes: current.strokes,
      selectedIds: selectedIds,
      scale: scale,
    );

    await _commitSelectionChange(
      beforeStrokes: current.strokes,
      updatedStrokes: updatedStrokes,
      errorMessage: 'Unable to resize the selected strokes.',
    );
  }

  Future<void> recolorSelection(int colorValue) async {
    final current = state.requireValue;
    final selectedIds = current.selection.selectedStrokeIds;

    if (current.isSaving || selectedIds.isEmpty) {
      return;
    }

    final updatedStrokes = _selectionTransformer.recolor(
      strokes: current.strokes,
      selectedIds: selectedIds,
      colorValue: colorValue,
    );

    await _commitSelectionChange(
      beforeStrokes: current.strokes,
      updatedStrokes: updatedStrokes,
      selectedColorValue: colorValue,
      errorMessage: 'Unable to recolor the selected strokes.',
    );
  }

  Future<void> _commitSelectionChange({
    required List<InkStroke> beforeStrokes,
    required List<InkStroke> updatedStrokes,
    required String errorMessage,
    int? selectedColorValue,
  }) async {
    final current = state.requireValue;
    final historyEntry = DrawingHistoryEntry(
      beforeStrokes: beforeStrokes,
      afterStrokes: updatedStrokes,
    );

    state = AsyncData(
      current.copyWith(
        strokes: updatedStrokes,
        colorValue: selectedColorValue ?? current.colorValue,
        undoHistory: [...current.undoHistory, historyEntry],
        redoHistory: const [],
        clearActiveStroke: true,
        isSaving: true,
      ),
    );

    await _persistHistoryState(errorMessage: errorMessage);
  }

  void copySelection() {
    final current = state.requireValue;
    final selectedIds = current.selection.selectedStrokeIds;

    if (selectedIds.isEmpty) {
      return;
    }

    final copiedStrokes = _selectionTransformer.copy(
      strokes: current.strokes,
      selectedIds: selectedIds,
    );

    state = AsyncData(
      current.copyWith(
        selection: current.selection.copyWith(clipboardStrokes: copiedStrokes),
      ),
    );
  }

  Future<void> pasteSelection() async {
    final current = state.requireValue;
    final clipboard = current.selection.clipboardStrokes;

    if (current.isSaving || clipboard.isEmpty) {
      return;
    }

    final existingIds = current.strokes.map((stroke) => stroke.id).toSet();
    final updatedStrokes = _selectionTransformer.paste(
      strokes: current.strokes,
      clipboard: clipboard,
      createId: _uuid.v4,
    );
    final pastedIds = updatedStrokes
        .where((stroke) => !existingIds.contains(stroke.id))
        .map((stroke) => stroke.id)
        .toSet();
    final historyEntry = DrawingHistoryEntry(
      beforeStrokes: current.strokes,
      afterStrokes: updatedStrokes,
    );

    state = AsyncData(
      current.copyWith(
        strokes: updatedStrokes,
        undoHistory: [...current.undoHistory, historyEntry],
        redoHistory: const [],
        selection: current.selection.copyWith(
          lassoPoints: const [],
          selectedStrokeIds: pastedIds,
          isDrawingLasso: false,
        ),
        clearActiveStroke: true,
        isSaving: true,
      ),
    );

    await _persistHistoryState(
      errorMessage: 'Unable to paste the selected strokes.',
    );
  }

  Future<void> deleteSelection() async {
    final current = state.requireValue;
    final selectedIds = current.selection.selectedStrokeIds;

    if (current.isSaving || selectedIds.isEmpty) {
      return;
    }

    final updatedStrokes = _selectionTransformer.delete(
      strokes: current.strokes,
      selectedIds: selectedIds,
    );

    final historyEntry = DrawingHistoryEntry(
      beforeStrokes: current.strokes,
      afterStrokes: updatedStrokes,
    );

    state = AsyncData(
      current.copyWith(
        strokes: updatedStrokes,
        undoHistory: [...current.undoHistory, historyEntry],
        redoHistory: const [],
        selection: current.selection.clearSelection(),
        clearActiveStroke: true,
        isSaving: true,
      ),
    );

    await _persistHistoryState(
      errorMessage: 'Unable to delete the selected strokes.',
    );
  }

  Future<void> undo() async {
    final current = state.requireValue;

    if (current.isSaving || current.undoHistory.isEmpty) {
      return;
    }

    final historyEntry = current.undoHistory.last;
    final remainingUndoHistory = current.undoHistory.sublist(
      0,
      current.undoHistory.length - 1,
    );

    state = AsyncData(
      current.copyWith(
        strokes: historyEntry.beforeStrokes,
        undoHistory: remainingUndoHistory,
        redoHistory: [...current.redoHistory, historyEntry],
        selection: current.selection.clearSelection(),
        clearActiveStroke: true,
        isSaving: true,
      ),
    );

    await _persistHistoryState(
      errorMessage: 'Unable to undo the drawing action.',
    );
  }

  Future<void> redo() async {
    final current = state.requireValue;

    if (current.isSaving || current.redoHistory.isEmpty) {
      return;
    }

    final historyEntry = current.redoHistory.last;
    final remainingRedoHistory = current.redoHistory.sublist(
      0,
      current.redoHistory.length - 1,
    );

    state = AsyncData(
      current.copyWith(
        strokes: historyEntry.afterStrokes,
        undoHistory: [...current.undoHistory, historyEntry],
        redoHistory: remainingRedoHistory,
        selection: current.selection.clearSelection(),
        clearActiveStroke: true,
        isSaving: true,
      ),
    );

    await _persistHistoryState(
      errorMessage: 'Unable to redo the drawing action.',
    );
  }

  void setInteractionMode(CanvasInteractionMode mode) {
    final current = state.requireValue;

    state = AsyncData(
      current.copyWith(
        interactionMode: mode,
        selection: mode == CanvasInteractionMode.ink
            ? current.selection.clearSelection()
            : current.selection,
        clearActiveStroke: true,
      ),
    );
  }

  void setEraserMode(EraserMode mode) {
    state = AsyncData(state.requireValue.copyWith(eraserMode: mode));
  }

  void selectTool(InkTool tool) {
    final current = state.requireValue;

    final settings = switch (tool) {
      InkTool.pen => (opacity: 1.0, width: 2.5),
      InkTool.pencil => (opacity: 0.72, width: 1.8),
      InkTool.highlighter => (opacity: 0.35, width: 18.0),
      InkTool.eraser => (opacity: 1.0, width: 18.0),
    };

    state = AsyncData(
      current.copyWith(
        selectedTool: tool,
        opacity: settings.opacity,
        strokeWidth: settings.width,
        interactionMode: CanvasInteractionMode.ink,
        selection: current.selection.clearSelection(),
      ),
    );
  }

  void setColor(int colorValue) {
    state = AsyncData(state.requireValue.copyWith(colorValue: colorValue));
  }

  void setStrokeWidth(double width) {
    if (width <= 0) {
      return;
    }

    state = AsyncData(state.requireValue.copyWith(strokeWidth: width));
  }

  Future<void> _persistHistoryState({required String errorMessage}) async {
    try {
      final repository = ref.read(inkRepositoryProvider);
      final currentStrokes = state.requireValue.strokes;

      await repository.clearPage(_pageId);

      if (currentStrokes.isNotEmpty) {
        await repository.saveAll(currentStrokes);
      }

      _finishSaving();
    } catch (_) {
      state = AsyncError(StateError(errorMessage), StackTrace.current);
    }
  }

  void _finishSaving() {
    state = AsyncData(state.requireValue.copyWith(isSaving: false));
  }

  List<DrawingHistoryEntry> _createInitialHistory(List<InkStroke> strokes) {
    final history = <DrawingHistoryEntry>[];

    for (var index = 0; index < strokes.length; index++) {
      history.add(
        DrawingHistoryEntry(
          beforeStrokes: strokes.sublist(0, index),
          afterStrokes: strokes.sublist(0, index + 1),
        ),
      );
    }

    return history;
  }
}
