// Copy all content into drawing_canvas.dart (unified scene).
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../page/domain/entities/note_page.dart';
import '../../../page/presentation/painters/paper_template_painter.dart';
import '../../../pdf/presentation/widgets/pdf_page_background.dart';
import '../../application/controllers/drawing_controller.dart';
import '../painters/ink_painter.dart';
import '../painters/selection_overlay_painter.dart';
import 'scene_object_layer.dart';

final class DrawingCanvas extends ConsumerStatefulWidget {
  const DrawingCanvas({
    required this.pageId,
    this.template = PageTemplate.blank,
    this.paperColor = PagePaperColor.paperWhite,
    this.pdfDocumentId,
    this.pdfPageNumber,
    super.key,
  }) : assert(
         (pdfDocumentId == null && pdfPageNumber == null) ||
             (pdfDocumentId != null && pdfPageNumber != null),
       );

  final String pageId;
  final PageTemplate template;
  final PagePaperColor paperColor;
  final String? pdfDocumentId;
  final int? pdfPageNumber;

  @override
  ConsumerState<DrawingCanvas> createState() => _DrawingCanvasState();
}

enum _SelectionGesture { none, lasso, move, resize, rotate }

final class _DrawingCanvasState extends ConsumerState<DrawingCanvas> {
  static const _straightenDelay = Duration(seconds: 3);
  static const _movementThresholdSquared = 4.0;
  static const _resizeHandleHitRadius = 20.0;

  final Stopwatch _strokeClock = Stopwatch();

  Timer? _straightenTimer;
  Offset? _lastAnchorPosition;
  Offset? _resizeCenter;
  Offset? _rotateCenter;
  bool _isStraightened = false;
  _SelectionGesture _selectionGesture = _SelectionGesture.none;

  @override
  void dispose() {
    _straightenTimer?.cancel();
    _strokeClock.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final drawing = ref.watch(drawingControllerProvider(widget.pageId));

    return drawing.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(child: Icon(Icons.error_outline)),
      data: (state) {
        final controller = ref.read(
          drawingControllerProvider(widget.pageId).notifier,
        );
        final selectedStrokes = state.strokes.where((stroke) {
          return state.selection.selectedStrokeIds.contains(stroke.id);
        }).toList();
        final selectionBounds = calculateSelectionBounds(selectedStrokes);

        return ClipRect(
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (event) {
              if (state.isNavigationMode ||
                  state.isTextMode ||
                  state.isImageMode) {
                _cancelActiveGesture();
                return;
              }

              _strokeClock
                ..reset()
                ..start();

              if (state.isLassoMode) {
                _beginSelectionGesture(
                  position: event.localPosition,
                  selectionBounds: selectionBounds,
                  controller: controller,
                );
                return;
              }

              _selectionGesture = _SelectionGesture.none;
              _isStraightened = false;
              _lastAnchorPosition = event.localPosition;

              controller.startStroke(
                x: event.localPosition.dx,
                y: event.localPosition.dy,
                pressure: _normalizedPressure(event),
                elapsedMicroseconds: 0,
              );
              _scheduleStraighten();
            },
            onPointerMove: (event) {
              if (state.isNavigationMode ||
                  state.isTextMode ||
                  state.isImageMode) {
                return;
              }

              if (state.isLassoMode) {
                _updateSelectionGesture(
                  position: event.localPosition,
                  controller: controller,
                );
                return;
              }

              controller.addPoint(
                x: event.localPosition.dx,
                y: event.localPosition.dy,
                pressure: _normalizedPressure(event),
                elapsedMicroseconds: _strokeClock.elapsedMicroseconds,
              );

              if (_isStraightened) {
                controller.straightenActiveStroke();
                return;
              }

              final anchor = _lastAnchorPosition;
              if (anchor == null ||
                  (event.localPosition - anchor).distanceSquared >=
                      _movementThresholdSquared) {
                _lastAnchorPosition = event.localPosition;
                _scheduleStraighten();
              }
            },
            onPointerUp: (_) {
              if (state.isNavigationMode ||
                  state.isTextMode ||
                  state.isImageMode) {
                _cancelActiveGesture();
                return;
              }

              if (state.isLassoMode) {
                _finishSelectionGesture(controller);
                return;
              }
              _finishStroke();
            },
            onPointerCancel: (_) {
              if (state.isNavigationMode ||
                  state.isTextMode ||
                  state.isImageMode) {
                _cancelActiveGesture();
                return;
              }

              if (state.isLassoMode) {
                _finishSelectionGesture(controller);
                return;
              }
              _finishStroke();
            },
            child: ColoredBox(
              color: Color(widget.paperColor.colorValue),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.pdfDocumentId case final documentId?)
                    PdfPageBackground(
                      documentId: documentId,
                      pageNumber: widget.pdfPageNumber!,
                    )
                  else
                    CustomPaint(
                      painter: PaperTemplatePainter(
                        template: widget.template,
                        lineColor: const Color(
                          0xFF7D8583,
                        ).withValues(alpha: 0.34),
                      ),
                    ),
                  SceneObjectLayer(
                    pageId: widget.pageId,
                    strokes: state.strokes,
                    interactionMode: state.interactionMode,
                  ),
                  if (state.activeStroke != null)
                    IgnorePointer(
                      child: CustomPaint(
                        painter: InkPainter(
                          strokes: const [],
                          activeStroke: state.activeStroke,
                        ),
                      ),
                    ),
                  IgnorePointer(
                    child: CustomPaint(
                      painter: SelectionOverlayPainter(
                        lassoPoints: state.selection.lassoPoints,
                        selectedStrokes: selectedStrokes,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _beginSelectionGesture({
    required Offset position,
    required Rect? selectionBounds,
    required DrawingController controller,
  }) {
    _straightenTimer?.cancel();
    _straightenTimer = null;
    _isStraightened = false;
    _lastAnchorPosition = null;

    if (selectionBounds != null) {
      final rotateHandle = selectionRotateHandleFor(selectionBounds);

      if ((position - rotateHandle).distance <= _resizeHandleHitRadius) {
        _selectionGesture = _SelectionGesture.rotate;
        _rotateCenter = selectionBounds.center;
        controller.beginSelectionRotate(
          angleRadians: math.atan2(
            position.dy - selectionBounds.center.dy,
            position.dx - selectionBounds.center.dx,
          ),
        );
        return;
      }
    }

    if (selectionBounds != null &&
        _isResizeHandleHit(position, selectionBounds)) {
      _selectionGesture = _SelectionGesture.resize;
      _resizeCenter = selectionBounds.center;
      _rotateCenter = null;
      controller.beginSelectionResize(
        distance: (position - selectionBounds.center).distance,
      );
      return;
    }

    if (selectionBounds != null && selectionBounds.contains(position)) {
      _selectionGesture = _SelectionGesture.move;
      _resizeCenter = null;
      _rotateCenter = null;
      controller.beginSelectionDrag(x: position.dx, y: position.dy);
      return;
    }

    _selectionGesture = _SelectionGesture.lasso;
    _resizeCenter = null;
    _rotateCenter = null;
    controller.beginLasso(
      x: position.dx,
      y: position.dy,
      elapsedMicroseconds: 0,
    );
  }

  void _updateSelectionGesture({
    required Offset position,
    required DrawingController controller,
  }) {
    switch (_selectionGesture) {
      case _SelectionGesture.lasso:
        controller.addLassoPoint(
          x: position.dx,
          y: position.dy,
          elapsedMicroseconds: _strokeClock.elapsedMicroseconds,
        );
      case _SelectionGesture.move:
        controller.updateSelectionDrag(x: position.dx, y: position.dy);
      case _SelectionGesture.resize:
        final center = _resizeCenter;
        if (center != null) {
          controller.updateSelectionResize(
            distance: (position - center).distance,
          );
        }
      case _SelectionGesture.rotate:
        final center = _rotateCenter;
        if (center != null) {
          controller.updateSelectionRotate(
            angleRadians: math.atan2(
              position.dy - center.dy,
              position.dx - center.dx,
            ),
          );
        }
      case _SelectionGesture.none:
        break;
    }
  }

  void _finishSelectionGesture(DrawingController controller) {
    _strokeClock.stop();

    switch (_selectionGesture) {
      case _SelectionGesture.lasso:
        controller.endLasso();
      case _SelectionGesture.move:
        unawaited(controller.endSelectionDrag());
      case _SelectionGesture.resize:
        unawaited(controller.endSelectionResize());
      case _SelectionGesture.rotate:
        unawaited(controller.endSelectionRotate());
      case _SelectionGesture.none:
        break;
    }

    _selectionGesture = _SelectionGesture.none;
    _resizeCenter = null;
    _rotateCenter = null;
  }

  bool _isResizeHandleHit(Offset position, Rect bounds) {
    final corners = [
      bounds.topLeft,
      bounds.topRight,
      bounds.bottomLeft,
      bounds.bottomRight,
    ];

    return corners.any(
      (corner) => (position - corner).distance <= _resizeHandleHitRadius,
    );
  }

  void _scheduleStraighten() {
    _straightenTimer?.cancel();
    _straightenTimer = Timer(_straightenDelay, () {
      if (!mounted) {
        return;
      }

      _isStraightened = true;
      ref
          .read(drawingControllerProvider(widget.pageId).notifier)
          .straightenActiveStroke();
    });
  }

  void _cancelActiveGesture() {
    _straightenTimer?.cancel();
    _straightenTimer = null;
    _lastAnchorPosition = null;
    _resizeCenter = null;
    _rotateCenter = null;
    _isStraightened = false;
    _selectionGesture = _SelectionGesture.none;
    _strokeClock.stop();
  }

  double _normalizedPressure(PointerEvent event) {
    final pressureRange = event.pressureMax - event.pressureMin;
    if (pressureRange <= 0) {
      return 0.5;
    }

    return ((event.pressure - event.pressureMin) / pressureRange)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  void _finishStroke() {
    _straightenTimer?.cancel();
    _straightenTimer = null;
    _lastAnchorPosition = null;
    _isStraightened = false;
    _strokeClock.stop();

    unawaited(
      ref.read(drawingControllerProvider(widget.pageId).notifier).endStroke(),
    );
  }
}
