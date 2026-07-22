// Copy all content into selection_overlay_painter.dart.
import 'package:flutter/material.dart';

import '../../domain/entities/ink_point.dart';
import '../../domain/entities/ink_stroke.dart';

const selectionRotateHandleOffset = 34.0;
const selectionHandleRadius = 7.0;

Rect? calculateSelectionBounds(
  List<InkStroke> selectedStrokes, {
  double padding = 10,
}) {
  final points = selectedStrokes.expand((stroke) => stroke.points).toList();

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

  return Rect.fromLTRB(
    minimumX - padding,
    minimumY - padding,
    maximumX + padding,
    maximumY + padding,
  );
}

Offset selectionRotateHandleFor(Rect bounds) {
  return Offset(bounds.center.dx, bounds.top - selectionRotateHandleOffset);
}

final class SelectionOverlayPainter extends CustomPainter {
  const SelectionOverlayPainter({
    required this.lassoPoints,
    required this.selectedStrokes,
  });

  final List<InkPoint> lassoPoints;
  final List<InkStroke> selectedStrokes;

  @override
  void paint(Canvas canvas, Size size) {
    _paintLasso(canvas);
    _paintSelectionBounds(canvas);
  }

  void _paintLasso(Canvas canvas) {
    if (lassoPoints.length < 2) {
      return;
    }

    final path = Path()..moveTo(lassoPoints.first.x, lassoPoints.first.y);

    for (final point in lassoPoints.skip(1)) {
      path.lineTo(point.x, point.y);
    }

    final paint = Paint()
      ..color = const Color(0xFF718D99)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, paint);
  }

  void _paintSelectionBounds(Canvas canvas) {
    final bounds = calculateSelectionBounds(selectedStrokes);

    if (bounds == null) {
      return;
    }

    final accent = const Color(0xFF718D99);
    final borderPaint = Paint()
      ..color = accent
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final fillPaint = Paint()
      ..color = accent.withValues(alpha: 0.07)
      ..style = PaintingStyle.fill;
    final roundedBounds = RRect.fromRectAndRadius(
      bounds,
      const Radius.circular(6),
    );

    canvas.drawRRect(roundedBounds, fillPaint);
    canvas.drawRRect(roundedBounds, borderPaint);

    final rotateHandle = selectionRotateHandleFor(bounds);
    canvas.drawLine(bounds.topCenter, rotateHandle, borderPaint);

    for (final corner in [
      bounds.topLeft,
      bounds.topRight,
      bounds.bottomLeft,
      bounds.bottomRight,
    ]) {
      _paintHandle(canvas, corner, showRotateMark: false);
    }

    _paintHandle(canvas, rotateHandle, showRotateMark: true);
  }

  void _paintHandle(
    Canvas canvas,
    Offset center, {
    required bool showRotateMark,
  }) {
    final accent = const Color(0xFF718D99);
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    final fillPaint = Paint()
      ..color = const Color(0xFFFAF9F5)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = accent
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(
      center + const Offset(0, 1),
      selectionHandleRadius + 1,
      shadowPaint,
    );
    canvas.drawCircle(center, selectionHandleRadius, fillPaint);
    canvas.drawCircle(center, selectionHandleRadius, borderPaint);

    if (!showRotateMark) {
      return;
    }

    final rotatePaint = Paint()
      ..color = accent
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final rotateRect = Rect.fromCircle(center: center, radius: 3.4);

    canvas.drawArc(rotateRect, -2.5, 4.3, false, rotatePaint);
    canvas.drawLine(
      center + const Offset(3.2, 1.4),
      center + const Offset(4.8, 0.8),
      rotatePaint,
    );
  }

  @override
  bool shouldRepaint(SelectionOverlayPainter oldDelegate) {
    return oldDelegate.lassoPoints != lassoPoints ||
        oldDelegate.selectedStrokes != selectedStrokes;
  }
}
