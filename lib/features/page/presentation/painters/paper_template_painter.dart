import 'package:flutter/material.dart';

import '../../domain/entities/note_page.dart';

final class PaperTemplatePainter extends CustomPainter {
  const PaperTemplatePainter({required this.template, required this.lineColor});

  final PageTemplate template;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.55
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    switch (template) {
      case PageTemplate.blank:
        return;

      case PageTemplate.ruled:
        _drawRuled(canvas: canvas, size: size, paint: paint);

      case PageTemplate.grid:
        _drawGrid(canvas: canvas, size: size, paint: paint);

      case PageTemplate.dotted:
        _drawDots(canvas: canvas, size: size, paint: paint);

      case PageTemplate.guideRuled:
        _drawGuideRuled(canvas: canvas, size: size, paint: paint);

      case PageTemplate.focusHeader:
        _drawFocusHeader(canvas: canvas, size: size, paint: paint);

      case PageTemplate.twinNotes:
        _drawTwinNotes(canvas: canvas, size: size, paint: paint);

      case PageTemplate.quietChecklist:
        _drawChecklist(canvas: canvas, size: size, paint: paint);
    }
  }

  void _drawRuled({
    required Canvas canvas,
    required Size size,
    required Paint paint,
  }) {
    for (double y = 54; y < size.height - 32; y += 28) {
      canvas.drawLine(Offset(32, y), Offset(size.width - 32, y), paint);
    }
  }

  void _drawGrid({
    required Canvas canvas,
    required Size size,
    required Paint paint,
  }) {
    for (double y = 28; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    for (double x = 28; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  void _drawDots({
    required Canvas canvas,
    required Size size,
    required Paint paint,
  }) {
    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    for (double y = 28; y < size.height; y += 28) {
      for (double x = 28; x < size.width; x += 28) {
        canvas.drawCircle(Offset(x, y), 0.85, dotPaint);
      }
    }
  }

  void _drawGuideRuled({
    required Canvas canvas,
    required Size size,
    required Paint paint,
  }) {
    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    for (double y = 54; y < size.height - 32; y += 28) {
      canvas.drawLine(Offset(32, y), Offset(size.width - 32, y), paint);

      for (double x = 88; x < size.width - 32; x += 56) {
        canvas.drawCircle(Offset(x, y), 0.85, dotPaint);
      }
    }
  }

  void _drawFocusHeader({
    required Canvas canvas,
    required Size size,
    required Paint paint,
  }) {
    canvas.drawLine(
      const Offset(40, 76),
      Offset(size.width - 40, 76),
      paint..strokeWidth = 0.9,
    );

    paint.strokeWidth = 0.55;

    for (double y = 118; y < size.height - 32; y += 28) {
      canvas.drawLine(Offset(40, y), Offset(size.width - 40, y), paint);
    }
  }

  void _drawTwinNotes({
    required Canvas canvas,
    required Size size,
    required Paint paint,
  }) {
    canvas.drawLine(
      Offset(size.width / 2, 40),
      Offset(size.width / 2, size.height - 40),
      paint,
    );
  }

  void _drawChecklist({
    required Canvas canvas,
    required Size size,
    required Paint paint,
  }) {
    for (double y = 58; y < size.height - 32; y += 34) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(40, y - 10, 13, 13),
          const Radius.circular(2),
        ),
        paint,
      );

      canvas.drawLine(Offset(68, y), Offset(size.width - 40, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant PaperTemplatePainter oldDelegate) {
    return template != oldDelegate.template ||
        lineColor != oldDelegate.lineColor;
  }
}
