import 'package:flutter/material.dart';

import '../../domain/entities/ink_point.dart';
import '../../domain/entities/ink_stroke.dart';

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

final class SelectionOverlayPainter extends CustomPainter {
  const SelectionOverlayPainter({
    required this.lassoPoints,
    required this.selectedStrokes,
  });

  static const handleRadius = 7.0;

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

    final fillPaint = Paint()
      ..color = const Color(0xFF718D99).withValues(alpha: 0.07)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFF718D99)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final roundedBounds = RRect.fromRectAndRadius(
      bounds,
      const Radius.circular(6),
    );

    canvas.drawRRect(roundedBounds, fillPaint);
    canvas.drawRRect(roundedBounds, borderPaint);

    for (final corner in _cornersOf(bounds)) {
      _paintResizeHandle(canvas, corner);
    }
  }

  List<Offset> _cornersOf(Rect bounds) {
    return [
      bounds.topLeft,
      bounds.topRight,
      bounds.bottomLeft,
      bounds.bottomRight,
    ];
  }

  void _paintResizeHandle(Canvas canvas, Offset center) {
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    final fillPaint = Paint()
      ..color = const Color(0xFFFAF9F5)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFF718D99)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(
      center + const Offset(0, 1),
      handleRadius + 1,
      shadowPaint,
    );
    canvas.drawCircle(center, handleRadius, fillPaint);
    canvas.drawCircle(center, handleRadius, borderPaint);
  }

  @override
  bool shouldRepaint(SelectionOverlayPainter oldDelegate) {
    return oldDelegate.lassoPoints != lassoPoints ||
        oldDelegate.selectedStrokes != selectedStrokes;
  }
}
